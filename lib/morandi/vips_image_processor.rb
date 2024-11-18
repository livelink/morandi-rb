# frozen_string_literal: true

require 'vips'

require 'morandi/srgb_conversion'

module Morandi
  # An alternative to ImageProcessor which is based on libvips for concurrent and less memory-intensive processing
  class VipsImageProcessor
    # Vips options are global, this method sets them for yielding, then restores to original
    def self.with_global_options(cache_max:, concurrency:)
      previous_cache_max = Vips.cache_max
      previous_concurrency = Vips.concurrency

      Vips.cache_set_max(cache_max)
      Vips.concurrency_set(concurrency)

      yield
    ensure
      Vips.cache_set_max(previous_cache_max)
      Vips.concurrency_set(previous_concurrency)
    end

    def initialize(path, user_options)
      @path = path

      @options = user_options

      @size_limit_on_load_px = @options['output.max']
      @output_width = @options['output.width']
      @output_height = @options['output.height']
    end

    def process!
      source_file_path = Morandi::SrgbConversion.perform(@path) || @path
      begin
        @img = Vips::Image.new_from_file(source_file_path)
      rescue Vips::Error => e
        # Match the known errors
        raise UnknownTypeError if /is not a known file format/.match?(e.message)
        raise CorruptImageError if /Premature end of JPEG file/.match?(e.message)

        # Re-raise generic Error when unknown
        raise Error, e.message
      end
      if @size_limit_on_load_px
        @scale = @size_limit_on_load_px.to_f / [@img.width, @img.height].max
        @img = @img.resize(@scale) if not_equal_to_one(@scale)
      else
        @scale = 1.0
      end

      return unless @options['output.limit'] && @output_width && @output_height

      scale_factor = [@output_width, @output_height].max.to_f / [@img.width, @img.height].max
      @img = @img.resize(scale_factor) if scale_factor < 1.0
    end

    def write_to_png(_write_to, _orientation = :any)
      raise 'not implemented'
    end

    def write_to_jpeg(write_to, quality = nil)
      process!

      quality ||= @options.fetch('quality', 97)

      @img.write_to_file(write_to, Q: quality)
    end

    private

    def not_equal_to_one(float)
      (float - 1.0).abs >= Float::EPSILON
    end
  end
end
