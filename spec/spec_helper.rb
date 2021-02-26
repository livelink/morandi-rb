# frozen_string_literal: true

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'fileutils'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  enable_coverage :branch if RUBY_VERSION >= '2.5.0'
end
require 'morandi'
require 'gdk_pixbuf_cairo'
require 'morandi_native'
require 'super_diff/rspec'

require 'pry'
require_relative 'visual_report_helper'
require_relative 'colour_helper'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
  config.include ColourHelper
  config.include VisualReportHelper

  config.before(:suite) do
    puts "Creating visual report #{VisualReportHelper.visual_report_path}"
  end

  config.after(:suite) do
    puts 'Reminder:'
    puts "Visual report is available here: #{VisualReportHelper.visual_report_path}"
    puts 'Coverage report is here: coverage/index.html'
  end
end

RSpec::Matchers.define :be_redish do
  match do |(red, green, blue)|
    red > 100 &&
      green < 50 &&
      blue < 50
  end
end

RSpec::Matchers.define :be_greyish do
  match do |colour|
    average = (colour.inject(&:+) / colour.size)
    colour.all? { |channel| (average - channel).abs < 15 }
  end
end
