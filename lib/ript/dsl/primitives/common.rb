#!/usr/bin/env ruby

module Ript
  module DSL
    module Primitives
      # Common
      module Common
        def label(label, opts = {})
          @labels[label] = opts
        end

        def interface(arg)
          @interface = arg
        end

        def ports(*args)
          if args.class == Array
            args.each do |port|
              @ports << if port.class == Range
                          "#{port.begin}:#{port.end}"
                        else
                          port
                        end
            end
          else
            port = args
            @ports << port
          end
        end

        def from(*label)
          label.flatten!(2)
          if label.is_a?(Array)
            label.each do |l|
              @froms << l
            end
          else
            @froms << label
          end
        end

        def to(*label)
          label.flatten!(2)
          if label.is_a?(Array)
            label.each do |l|
              @tos << l
            end
          else
            @tos << label
          end
        end

        def protocols(*args)
          # FIXME: refactor to just use flatten!
          if args.class == Array
            args.each do |protocol|
              @protocols << protocol
            end
          else
            protocol = args
            @protocols << protocol
          end
        end

        def validate(opts = {})
          opts.each_pair do |type, label|
            unless label_exists?(label)
              raise LabelError, "Address '#{label}' (a #{type}) isn't defined"
            end
          end
        end

        def label_exists?(label)
          @labels.key?(label)
        end
      end
    end
  end
end
