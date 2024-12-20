# frozen_string_literal: true

require 'vips'

require 'morandi/srgb_conversion'
require 'morandi/operation/vips_straighten'

module Morandi
  # An alternative to ImageProcessor which is based on libvips for concurrent and less memory-intensive processing
  class VipsImageProcessor
    # Colour filter related constants
    RGB_LUMINANCE_EXTRACTION_FACTORS = [0.3086, 0.6094, 0.0820].freeze
    SEPIA_MODIFIER = [25, 5, -25].freeze
    BLUETONE_MODIFIER = [-10, 5, 25].freeze
    COLOUR_FILTER_MODIFIERS = {
      'sepia' => SEPIA_MODIFIER,
      'bluetone' => BLUETONE_MODIFIER
    }.freeze
    SUPPORTED_FILTERS = COLOUR_FILTER_MODIFIERS.keys + ['greyscale']

    def self.supports?(input, options)
      return false unless input.is_a?(String)
      return false if options['brighten'].to_f != 0
      return false if options['contrast'].to_f != 0
      return false if options['sharpen'].to_f != 0
      return false if options['redeye']&.any?
      return false if options['border-style']
      return false if options['background-style']

      true
    end

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

      apply_gamma!
      apply_rotate!
      apply_crop!
      apply_filters!

      if @options['output.limit'] && @output_width && @output_height
        scale_factor = [@output_width, @output_height].max.to_f / [@img.width, @img.height].max
        @img = @img.resize(scale_factor) if scale_factor < 1.0
      end

      strip_alpha!
      ensure_srgb!
    end

    def write_to_png(_write_to, _orientation = :any)
      raise 'not implemented'
    end

    def write_to_jpeg(target_path, quality = nil)
      process!

      quality ||= @options.fetch('quality', 97)

      target_path_jpg = "#{target_path}.jpg" # Vips chooses format based on file extension, this ensures jpg
      @img.write_to_file(target_path_jpg, Q: quality)
      FileUtils.mv(target_path_jpg, target_path)
    end

    private

    # Remove the alpha channel if present. Vips supports alpha, but the current Pixbuf processor happens to strip it in
    # most cases (straighten and cropping beyond image bounds are exceptions)
    #
    # Alternatively, alpha can be left intact for more accurate processing and transparent output or merged into an
    # image using Vips::Image#flatten for less resource-intensive processing
    def strip_alpha!
      @img = @img.extract_band(0, n: @img.bands - 1) if @img.has_alpha?
    end

    def apply_gamma!
      return unless @options['gamma'] && not_equal_to_one(@options['gamma'])

      @img = @img.gamma(exponent: @options['gamma'])
    end

    def angle
      @options['angle'].to_i % 360
    end

    def apply_rotate!
      @img = case angle
             when 0 then @img
             when 90 then @img.rot90
             when 180 then @img.rot180
             when 270 then @img.rot270
             else raise('"angle" option only accepts multiples of 90')
             end

      unless @options['straighten'].to_f.zero?
        @img = Morandi::Operation::VipsStraighten.new_from_hash(angle: @options['straighten'].to_f).call(@img)
      end

      @image_width = @img.width
      @image_height = @img.height
    end

    def apply_crop!
      crop = @options['crop']

      return if crop.nil? && @options['image.auto-crop'].eql?(false)

      crop = crop.split(',').map(&:to_i) if crop.is_a?(String) && crop =~ /^\d+,\d+,\d+,\d+/

      crop = nil unless crop.is_a?(Array) && crop.size.eql?(4) && crop.all? do |i|
        i.is_a?(Numeric)
      end
      # can't crop, won't crop
      return if @output_width.nil? && @output_height.nil? && crop.nil?

      crop = crop.map { |s| (s.to_f * @scale).floor } if crop && not_equal_to_one(@scale)
      crop ||= Morandi::CropUtils.autocrop_coords(@img.width, @img.height, @output_width, @output_height)
      @img = Morandi::CropUtils.apply_crop_vips(@img, crop[0], crop[1], crop[2], crop[3])
    end

    def apply_filters!
      filter_name = @options['fx']
      return unless SUPPORTED_FILTERS.include?(filter_name)

      # The filter-related constants assume RGB colourspace, so it requires early conversion
      ensure_srgb!

      # Convert to greyscale using weights
      rgb_factors = RGB_LUMINANCE_EXTRACTION_FACTORS
      recombination_matrix = [rgb_factors, rgb_factors, rgb_factors]
      if @img.has_alpha?
        # Add "0" multiplier for alpha to ignore it for luminance calculation
        recombination_matrix = recombination_matrix.map { |channel_multipliers| channel_multipliers + [0] }
        # Add fourth row in the matrix to preserve unchanged alpha channel
        recombination_matrix << [0, 0, 0, 1]
      end
      @img = @img.recomb(recombination_matrix)

      return unless COLOUR_FILTER_MODIFIERS[filter_name]

      # Apply colour adjustment based on the modifiers setup
      colour_filter_modifier = COLOUR_FILTER_MODIFIERS[filter_name]
      colour_filter_modifier += [0] if @img.has_alpha?
      @img = @img.linear(1.0, colour_filter_modifier)
    end

    def not_equal_to_one(float)
      (float - 1.0).abs >= Float::EPSILON
    end

    def ensure_srgb!
      @img = @img.colourspace(:srgb) unless @img.interpretation == :srgb
    end
  end
end
