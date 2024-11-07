# frozen_string_literal: true

require 'fileutils'
require 'open3'

module Morandi
  module SpecSupport
    class ImageComparison
      NORMALIZED_ERROR_VALUE_REGEXP = /\A.+ \((.+)\)\z/.freeze

      # Tolerance is a number between 0 (must be identical) and 1 (can completely differ)
      def initialize(reference_path:, tested_path:, diff_path:, tolerance: 0)
        @reference_path = reference_path
        @tested_path = tested_path
        @diff_path = diff_path
        @tolerance = tolerance
      end

      def normalized_mean_error
        cmd = ['compare',
               '-metric', 'mae', # Stands for "Mean Average Error"
               @reference_path,
               @tested_path,
               @diff_path]
        _stdout, stderr, _status = Open3.capture3(*cmd)
        extract_normalized_absolute_error(stderr)
      end

      private

      def extract_normalized_absolute_error(compare_output)
        match_data = NORMALIZED_ERROR_VALUE_REGEXP.match(compare_output)
        raise "Can't extract error value from following data:\n#{compare_output}" unless match_data && match_data[1]

        match_data[1].to_f
      end
    end

    # Takes the images related to a failed test and puts them in a single place for ease of inspection
    class ImageDebugData
      OUTPUT_ROOT = 'tmp/reference-image-matches'

      attr_reader :exposed_reference_path, :exposed_tested_path, :exposed_diff_path

      def initialize(name, file_type)
        sanitised_name = name.gsub(/[^a-zA-Z0-9_-]+/, '-')
        @output_dir = File.join(OUTPUT_ROOT, sanitised_name)
        @exposed_reference_path = File.join(@output_dir, "reference.#{file_type}")
        @exposed_tested_path = File.join(@output_dir, "tested.#{file_type}")
        @exposed_diff_path = File.join(@output_dir, 'diff.png')
      end

      def expose_from(reference_path:, tested_path:, diff_path:)
        FileUtils.mkdir_p(@output_dir)
        FileUtils.cp(tested_path, @exposed_tested_path)
        FileUtils.cp(reference_path, @exposed_reference_path)
        FileUtils.cp(diff_path, @exposed_diff_path)
      end
    end
  end
end

RSpec::Matchers.define :match_reference_image do |reference_name, file_type: 'jpg', tolerance: 0|
  reference_path = File.join('spec/fixtures/reference_images', "#{reference_name}.#{file_type}")

  match do |tested_path|
    tmp_diff = Tempfile.new('test-diff')
    comparison = Morandi::SpecSupport::ImageComparison.new(reference_path: reference_path,
                                                           tested_path: tested_path,
                                                           diff_path: tmp_diff.path,
                                                           tolerance: tolerance)
    @normalized_mean_error = comparison.normalized_mean_error
    return true if @normalized_mean_error <= tolerance

    metadata = RSpec.current_example.metadata
    spec_name = "#{metadata[:absolute_file_path].split('/spec/').last}:#{metadata[:scoped_id]}"
    @debug_data = Morandi::SpecSupport::ImageDebugData.new(spec_name, file_type)

    @debug_data.expose_from(reference_path: reference_path, tested_path: tested_path, diff_path: tmp_diff.path)
    false
  ensure
    tmp_diff.close!
  end

  failure_message do
    <<~TXT
      The provided image and reference image do not match (error: #{@normalized_mean_error}, tolerance: #{tolerance})
      EXPECTED: #{@debug_data.exposed_reference_path}
      ACTUAL: #{@debug_data.exposed_tested_path}
      DIFF: #{@debug_data.exposed_diff_path}

      After manually confirming that the difference is expected, run:
      cp #{@debug_data.exposed_tested_path} #{reference_path}
    TXT
  end
end
