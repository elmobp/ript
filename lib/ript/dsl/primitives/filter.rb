#!/usr/bin/env ruby

module Ript
  module DSL
    module Primitives
      # Filter
      module Filter
        # Accept traffic to/from a destination/source.
        #
        # This allows traffic for a particular port/protocol to be passed into
        # userland on the local machine.
        def accept(name, opts = {}, &block)
          opts[:jump] = 'ACCEPT'
          build_rule(name, block, opts)
        end

        # Reject traffic to/from a destination/source.
        #
        # Send an error packet back for traffic that matches.
        def reject(name, opts = {}, &block)
          opts[:jump] = 'REJECT'
          build_rule(name, block, opts)
        end

        # Drop traffic to/from a destination/source.
        #
        # Silently drop packets that match.
        def drop(name, opts = {}, &block)
          opts[:jump] = 'DROP'
          build_rule(name, block, opts)
        end

        # Log traffic to/from a destination/source.
        #
        # Log packets that match via the kernel log (read with dmesg or syslog).
        def log(name, opts = {}, &block)
          opts[:jump] = 'LOG'
          build_rule(name, block, opts)
        end

        private

        # Construct a rule to be applied to the `filter` table.
        #
        # This method is used to construct simple rules on the filter table to
        # accept/reject/drop/log traffic to and from various addresses.
        #
        # Accepts a block of the actual rule definition to evaluate, and
        # appends the generated rule to the @table instance variable on the
        # partition instance.
        #
        # This method returns nothing.
        #
        def build_rule(_name, block, opts = {})
          @froms     = []
          @tos       = []
          @ports     = []
          @protocols = []
          insert     = opts[:insert] || 'partition-a'
          jump       = opts[:jump]   || 'DROP'
          log        = opts[:log]

          # Evaluate the block.
          instance_eval(&block)

          # Default all rules to apply to TCP packets if no protocol is specified
          @protocols << 'TCP' if @protocols.empty?

          @protocols.map! { |protocol| {'protocol' => protocol} }
          @ports.map!     { |port| {'dport' => port} }

          # Provide a default from address, so the @ports => @protocols => @froms
          # nested iteration below works.
          @froms << 'all' if @froms.empty?

          @froms.each do |from|
            @tos.each do |to|
              validate(from: from, to: to)

              from_address  = @labels[from][:address]
              to_address    = @labels[to][:address]

              attributes = {
                'table'       => 'filter',
                'insert'      => insert,
                'destination' => to_address,
                'jump'        => "#{@name}-a"
              }
              @input << Rule.new(attributes)
              @input << Rule.new(attributes.merge('jump' => 'LOG')) if log

              attributes = {
                'table'       => 'filter',
                'append'      => "#{@name}-a",
                'destination' => to_address,
                'source'      => from_address,
                'jump'        => jump
              }
              attributes.insert_before('destination', ['in-interface', @interface]) if @interface
              # Build up a list of arguments we need to build expanded rules.
              #
              # This allows us to expand shorthand definitions like:
              #
              #   accept "multiple rules in one" do
              #     from "foo", "bar", "baz"
              #     to   "spoons"
              #   end
              #
              # ... into multiple rules, one ACCEPT rule for foo, bar, baz.
              #
              arguments = if !@ports.empty? && !@protocols.empty?
                            # build the rules based on the arguments supplied
                            @protocols.product(@ports).map { |ary| ary.inject(:merge) }
                          elsif @ports.empty? && !@protocols.empty?
                            @protocols
                          elsif @protocols.empty? && !@ports.empty?
                            @ports
                          else
                            []
                          end

              # If we have arguments, iterate through them
              if !arguments.empty?
                arguments.each do |options|
                  options.each_pair do |key, value|
                    if value.is_a?(Array)
                      supported_protocols = IO.readlines('/etc/protocols')
                      ignored_values = %w(all tcp udp)
                      supported_protocols.map! {|proto| proto.split("\t")[0] }
                      if key == "protocol" and value.instance_of?(String) and !ignored_values.include? value.downcase and value != "" and !supported_protocols.include? value
                              puts "Invalid protocol #{value} specified cannot continue"
                              exit
                      end
                      supported_protocols.map! { |proto| proto.split("\t")[0] }
                      value.each do |valueout|
                        if !ignored_values.include? valueout.downcase and !supported_protocols.include? valueout
                          puts 'Invalid protocol specified cannot continue'
                          exit 100
                        end
                        attributes = attributes.dup # avoid overwriting existing hash values from previous iterations
                        attributes.insert_before('destination', [key, valueout])
                        @table << Rule.new(attributes.merge('jump' => 'LOG')) if log
                        @table << Rule.new(attributes)
                      end
                      break
                    else
                      attributes = attributes.dup # avoid overwriting existing hash values from previous iterations
                      attributes.insert_before('destination', [key, value])
                    end
                  end
                  @table << Rule.new(attributes.merge('jump' => 'LOG')) if log
                  @table << Rule.new(attributes)
                end
              else
                @table << Rule.new(attributes.merge('jump' => 'LOG')) if log
                @table << Rule.new(attributes)
              end # if
            end # @tos.each
          end # @froms.each
        end # def build_rule
      end
    end
  end
end
