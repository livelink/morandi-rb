# frozen_string_literal: true

require 'morandi/profiled_pixbuf'
require 'morandi/redeye'
require 'morandi/operation/straighten'
require 'morandi/operation/colourify'
require 'morandi/operation/image_border'

module Morandi
  # rubocop:disable Metrics/ClassLength

  # ImageProcessor transforms an image.
  class ImageProcessor
    attr_reader :options, :pb
    attr_accessor :config

    def initialize(file, user_options, local_options = {})
      @file = file

      user_options.keys.grep(/^path/).each { |k| user_options.delete(k) }

      # Give priority to user_options
      @options = (local_options || {}).merge(user_options || {})
      @local_options = local_options

      @max_size_px = @options['output.max']
      @width = @options['output.width']
      @height = @options['output.height']
    end

    def process!
      case @file
      when String
        get_pixbuf
      when GdkPixbuf::Pixbuf, Morandi::ProfiledPixbuf
        @pb = @file
        @scale = 1.0
      end

      # Apply Red-Eye corrections
      apply_redeye!

      # Apply contrast, brightness etc
      apply_colour_manipulations!

      # apply rotation
      apply_rotate!

      # apply crop
      apply_crop!

      # apply filter
      apply_filters!

      # add border
      apply_decorations!

      @pb = @pb.scale_max([@width, @height].max) if @options['output.limit'] && @width && @height

      @pb
    rescue GdkPixbuf::PixbufError::UnknownType => e
      raise UnknownTypeError, e.message
    rescue GdkPixbuf::PixbufError::CorruptImage => e
      raise CorruptImageError, e.message
    end

    # Returns generated pixbuf
    def result
      process! unless @pb
      @pb
    end

    def write_to_png(write_to, orientation = :any)
      pb = @pb

      case orientation
      when :landscape
        pb = @pb.rotate(90) if @pb.width < @pb.height
      when :portrait
        pb = @pb.rotate(90) if @pb.width > @pb.height
      end
      pb.save(write_to, 'png')
    end

    def write_to_jpeg(write_to, quality = nil)
      quality ||= options.fetch('quality', '97')
      @pb.save(write_to, 'jpeg', quality: quality.to_s)
    end

    protected

    def get_pixbuf
      _, width, height = GdkPixbuf::Pixbuf.get_file_info(@file)
      @pb = Morandi::ProfiledPixbuf.new(@file, @local_options, @max_size_px)

      # Everything below probably could be substituted with the following:
      # @scale = @max_size_px ? @max_size_px / [width, height].max : 1.0
      actual_max = [@pb.width, @pb.height].max
      src_max = if @max_size_px
                   [width, height].max
                 else
                   [@pb.width, @pb.height].max
                 end

      @scale = actual_max / src_max.to_f
    end

    SHARPEN = [
      -1, -1, -1, -1, -1,
      -1,  2,  2,  2, -1,
      -1,  2,  8,  2, -1,
      -1,  2,  2,  2, -1,
      -1, -1, -1, -1, -1
    ].freeze

    BLUR = [
      0, 1, 1, 1, 0,
      1, 1, 1, 1, 1,
      1, 1, 1, 1, 1,
      1, 1, 1, 1, 1,
      0, 1, 1, 1, 0
    ].freeze

    def apply_colour_manipulations!
      if options['brighten'].to_i.nonzero?
        brighten = (5 * options['brighten']).clamp(-100, 100)
        @pb = MorandiNative::PixbufUtils.brightness(@pb, brighten)
      end

      if options['gamma'] && not_equal_to_one(options['gamma'])
        @pb = MorandiNative::PixbufUtils.gamma(@pb,
                                               options['gamma'])
      end

      if options['contrast'].to_i.nonzero?
        contrast = (5 * options['contrast']).clamp(-100, 100)
        @pb = MorandiNative::PixbufUtils.contrast(@pb, contrast)
      end

      return unless options['sharpen'].to_i.nonzero?

      if options['sharpen'].positive?
        [options['sharpen'], 5].min.times do
          @pb = MorandiNative::PixbufUtils.filter(@pb, SHARPEN, SHARPEN.inject(0, &:+))
        end
      elsif options['sharpen'].negative?
        [(options['sharpen'] * -1), 5].min.times do
          @pb = MorandiNative::PixbufUtils.filter(@pb, BLUR, BLUR.inject(0, &:+))
        end
      end
    end

    def apply_redeye!
      (options['redeye'] || []).each do |eye|
        @pb = Morandi::RedEye::TapRedEye.tap_on(@pb, eye[0] * @scale, eye[1] * @scale)
      end
    end

    def angle
      a = options['angle'].to_i
      (360 - a) % 360 if a
    end

    # modifies @pb with any applied rotation
    def apply_rotate!
      a = angle

      @pb = @pb.rotate(a) unless (a % 360).zero?

      unless options['straighten'].to_f.zero?
        @pb = Morandi::Operation::Straighten.new_from_hash(angle: options['straighten'].to_f).call(@pb)
      end

      @image_width = @pb.width
      @image_height = @pb.height
    end

    DEFAULT_CONFIG = {
      'border-size-mm' => 5
    }.freeze
    def config_for(key)
      return options[key] if options&.key?(key)
      return @config[key] if @config&.key?(key)

      DEFAULT_CONFIG[key]
    end

    def apply_crop!
      crop = options['crop']

      return if crop.nil? && config_for('image.auto-crop').eql?(false)

      crop = crop.split(',').map(&:to_i) if crop.is_a?(String) && crop =~ /^\d+,\d+,\d+,\d+/

      crop = nil unless crop.is_a?(Array) && crop.size.eql?(4) && crop.all? do |i|
        i.is_a?(Numeric)
      end

      # can't crop, won't crop
      return if @width.nil? && @height.nil? && crop.nil?

      crop = crop.map { |s| (s.to_f * @scale).floor } if crop && not_equal_to_one(@scale)

      crop ||= Morandi::CropUtils.autocrop_coords(@pb.width, @pb.height, @width, @height)

      @pb = Morandi::CropUtils.apply_crop(@pb, crop[0], crop[1], crop[2], crop[3])
    end

    def apply_filters!
      filter = options['fx']

      case filter
      when 'greyscale', 'sepia', 'bluetone'
        op = Morandi::Operation::Colourify.new_from_hash('filter' => filter)
      else
        return
      end
      @pb = op.call(@pb)
    end

    def apply_decorations!
      style = options['border-style']
      colour = options['background-style']

      return if style.nil? || style.eql?('none')
      return if colour.eql?('none')

      colour ||= 'black'

      crop = options['crop']
      crop = crop.map { |s| (s.to_f * @scale).floor } if crop && not_equal_to_one(@scale)

      op = Morandi::Operation::ImageBorder.new_from_hash(
        'style' => style,
        'colour' => colour || '#000000',
        'crop' => crop,
        'size' => [@image_width, @image_height],
        'print_size' => [@width, @height],
        'shrink' => true,
        'border_size' => @scale * config_for('border-size-mm').to_i * 300 / 25.4 # 5mm at 300dpi
      )

      @pb = op.call(@pb)
    end

    private

    def not_equal_to_one(float)
      (float - 1.0).abs >= Float::EPSILON
    end
  end
  # rubocop:enable Metrics/ClassLength
end
