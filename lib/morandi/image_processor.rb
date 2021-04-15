# frozen_string_literal: true

require 'morandi/profiled_pixbuf'
require 'morandi/redeye'

module Morandi
  class ImageProcessor
    attr_reader :options, :pb
    attr_accessor :config

    def self.default_icc_path(path)
      "#{path}.icc.jpg"
    end

    def initialize(file, user_options, local_options = {})
      @file = file

      user_options.keys.grep(/^path/).each { |k| user_options.delete(k) }

      # Give priority to user_options
      @options = (local_options || {}).merge(user_options || {})
      @local_options = local_options

      @scale_to = @options['output.max']
      @width = @options['output.width']
      @height = @options['output.height']

      case @file
      when String
        get_pixbuf
      when GdkPixbuf::Pixbuf, Morandi::ProfiledPixbuf
        @pb = @file
        @scale = 1.0
      end
    end

    def process!
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

      # apply shrink to fit
      apply_shrink_to_fit!

      @pb = @pb.scale_max([@width, @height].max) if @options['output.limit'] && @width && @height

      @pb
    end

    def result
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
      @pb = Morandi::ProfiledPixbuf.new(@file, @local_options, @scale_to)
      @actual_max = [@pb.width, @pb.height].max

      @src_max = if @scale_to
                   [width, height].max
                 else
                   [@pb.width, @pb.height].max
                 end

      @scale = @actual_max / @src_max.to_f
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
        brighten = [[5 * options['brighten'], -100].max, 100].min
        @pb = PixbufUtils.brightness(@pb, brighten)
      end

      @pb = PixbufUtils.gamma(@pb, options['gamma']) if options['gamma'] && not_equal_to_one(options['gamma'])

      if options['contrast'].to_i.nonzero?
        @pb = PixbufUtils.contrast(@pb,
                                   [[5 * options['contrast'], -100].max, 100].min)
      end

      return unless options['sharpen'].to_i.nonzero?

      if options['sharpen'].positive?
        [options['sharpen'], 5].min.times do
          @pb = PixbufUtils.filter(@pb, SHARPEN, SHARPEN.inject(0, &:+))
        end
      elsif options['sharpen'].negative?
        [(options['sharpen'] * -1), 5].min.times do
          @pb = PixbufUtils.filter(@pb, BLUR, BLUR.inject(0, &:+))
        end
      end
    end

    def apply_redeye!
      options['redeye'] || [].each do |eye|
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

      @pb = Morandi::Straighten.new(options['straighten'].to_f).call(nil, @pb) unless options['straighten'].to_f.zero?

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

      crop = crop.split(/,/).map(&:to_i) if crop.is_a?(String) && crop =~ /^\d+,\d+,\d+,\d+/

      crop = nil unless crop.is_a?(Array) && crop.size.eql?(4) && crop.all? do |i|
        i.is_a?(Numeric)
      end

      # can't crop, won't crop
      return if @width.nil? && @height.nil? && crop.nil?

      crop = [0, 0, crop[2], crop[3]] if negative_crop? # X and Y crops are 0 so the original image is still in tack for Shrink to fit.

      crop = crop.map { |s| (s.to_f * @scale).floor } if crop && not_equal_to_one(@scale)

      crop ||= Morandi::Utils.autocrop_coords(@pb.width, @pb.height, @width, @height)

      @pb = Morandi::Utils.apply_crop(@pb, crop[0], crop[1], crop[2], crop[3])
    end

    def apply_filters!
      filter = options['fx']

      case filter
      when 'greyscale', 'sepia', 'bluetone'
        op = Morandi::Colourify.new_from_hash('op' => filter)
      else
        return
      end
      @pb = op.call(nil, @pb)
    end

    def apply_decorations!
      style = options['border-style']
      colour = options['background-style']

      return if style.nil? || style.eql?('none')
      return if colour.eql?('none')

      colour ||= 'black'

      crop = options['crop']
      crop = crop.map { |s| (s.to_f * @scale).floor } if crop && not_equal_to_one(@scale)

      op = Morandi::ImageBorder.new_from_hash(
        'style' => style,
        'colour' => colour || '#000000',
        'crop' => crop,
        'size' => [@image_width, @image_height],
        'print_size' => [@width, @height],
        'shrink' => true,
        'border_size' => @scale * config_for('border-size-mm').to_i * 300 / 25.4 # 5mm at 300dpi
      )

      @pb = op.call(nil, @pb)
    end

    def apply_shrink_to_fit!
      return unless negative_crop?

      op = Morandi::ShrinkToFit.new_from_hash(
        'crop' => options['crop'],
        'size' => [@image_width, @image_height],
        'print_size' => [@width, @height],
        'shrink' => true,
      )

      @pb = op.call(nil, @pb)
    end

    private

    def not_equal_to_one(float)
      (float - 1.0) >= Float::EPSILON
    end

    def negative_crop?
      # Pretty sure this can be incorporated into the apply_crop! incase it comes as a string.
      return unless crop = options['crop']
      crop[0].to_i.negative? || crop[1].to_i.negative?
    end

    def largest_shrink_option
      proportional_width = @width.to_f / @image_width.to_f
      proportional_height = @height.to_f / @image_height.to_f
      if proportional_height >= 1 && proportional_width >= 1
        return [@image_width, @image_height]
      end
      options = [[(@image_width*proportional_width).round, (@image_height*proportional_width).round],
                [(@image_width*proportional_height).round, (@image_height*proportional_height).round]]
      
      options.select { |option| option[0] <= @width && option[1] <= @height }.max
    end
  end
end
