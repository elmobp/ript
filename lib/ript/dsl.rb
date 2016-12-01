#!/usr/bin/env ruby

if RUBY_VERSION =~ /^1.8/
  puts 'Ript requires Ruby 1.9 to run. Exiting.'
  exit 2
end

$LOAD_PATH << Pathname.new(__FILE__).dirname.parent.expand_path.to_s
require 'pp'
require 'ript/dsl/primitives'
require 'ript/rule'
require 'ript/partition'
require 'ript/exceptions'
require 'ript/patches'
