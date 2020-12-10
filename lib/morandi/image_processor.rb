require 'morandi/profiled_pixbuf'
require 'morandi/redeye'

class Morandi::ImageProcessor
  attr_reader :options, :pb
  attr_accessor :config

  def self.default_icc_path(path)
    "#{path}.icc.jpg"
  end

  def initialize(file, user_options, local_options={})
    @file = file

    user_options.keys.grep(/^path/).each { |k| user_options.delete(k) }

    # Give priority to user_options
    @options = (local_options || {}).merge(user_options || {})
    @local_options = local_options

    @scale_to = @options['output.max']
    @width, @height = @options['output.width'], @options['output.height']

    if @file.is_a?(String)
      get_pixbuf
    elsif @file.is_a?(GdkPixbuf::Pixbuf) or @file.is_a?(Morandi::ProfiledPixbuf)
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

    if @options['output.limit'] && @width && @height
      @pb = @pb.scale_max([@width, @height].max)
    end

    @pb
  end

  def result
    @pb
  end

  def write_to_png(fn, orientation=:any)
    pb = @pb

    case orientation
    when :landscape
      pb = @pb.rotate(90) if @pb.width < @pb.height
    when :portrait
      pb = @pb.rotate(90) if @pb.width > @pb.height
    end
    pb.save(fn, 'png')
  end

  def write_to_jpeg(fn, quality = nil)
    quality ||= options.fetch('quality', '97')
    @pb.save(fn, 'jpeg', quality: quality.to_s)
  end

protected
  def get_pixbuf
    _, width, height = GdkPixbuf::Pixbuf.get_file_info(@file)

    if @scale_to
      @pb = Morandi::ProfiledPixbuf.new(@file, @scale_to, @scale_to, @local_options)
      @src_max = [width, height].max
      @actual_max = [@pb.width, @pb.height].max
    else
      @pb = Morandi::ProfiledPixbuf.new(@file, @local_options)
      @src_max = [@pb.width, @pb.height].max
      @actual_max = [@pb.width, @pb.height].max
    end

    @scale = @actual_max / @src_max.to_f
  end

  SHARPEN = [
    -1, -1, -1, -1, -1,
    -1,  2,  2,  2, -1,
    -1,  2,  8,  2, -1,
    -1,  2,  2,  2, -1,
    -1, -1, -1, -1, -1,
  ]
  BLUR = [
    0, 1, 1, 1, 0,
    1, 1, 1, 1, 1,
    1, 1, 1, 1, 1,
    1, 1, 1, 1, 1,
    0, 1, 1, 1, 0,
  ]

  def apply_colour_manipulations!
    if options['brighten'].to_i.nonzero?
      brighten = [ [ 5 * options['brighten'], -100 ].max, 100 ].min
      @pb = PixbufUtils.brightness(@pb, brighten)
    end

    if options['gamma'] && (options['gamma'] != 1.0)
      @pb = PixbufUtils.gamma(@pb, options['gamma'])
    end

    if options['contrast'].to_i.nonzero?
      @pb = PixbufUtils.contrast(@pb, [ [ 5 * options['contrast'], -100 ].max, 100 ].min)
    end

    if options['sharpen'].to_i.nonzero?
      if options['sharpen'] > 0
        [options['sharpen'], 5].min.times do
          @pb = PixbufUtils.filter(@pb, SHARPEN, SHARPEN.inject(0, &:+))
        end
      elsif options['sharpen'] < 0
        [ (options['sharpen']*-1), 5].min.times do
          @pb = PixbufUtils.filter(@pb, BLUR, BLUR.inject(0, &:+))
        end
      end
    end
  end

  def apply_redeye!
    for eye in options['redeye'] || []
      @pb = Morandi::RedEye::TapRedEye.tap_on(@pb, eye[0] * @scale, eye[1] * @scale)
    end
  end

  def angle
    a = options['angle'].to_i
    if a
      (360-a)%360
    else
      nil
    end
  end

  # modifies @pb with any applied rotation
  def apply_rotate!
    a = angle()

    unless (a%360).zero?
      @pb = @pb.rotate(a)
    end

    unless options['straighten'].to_f.zero?
      @pb = Morandi::Straighten.new(options['straighten'].to_f).call(nil, @pb)
    end

    @image_width = @pb.width
    @image_height = @pb.height
  end

  DEFAULT_CONFIG = {
    'border-size-mm' => 5
  }
  def config_for(key)
    return options[key] if options && options.has_key?(key)
    return @config[key] if @config && @config.has_key?(key)
    DEFAULT_CONFIG[key]
  end

  #
  def apply_crop!
    crop = options['crop']

    if crop.nil? && config_for('image.auto-crop').eql?(false)
      return
    end

    if crop.is_a?(String) && crop =~ /^\d+,\d+,\d+,\d+/
      crop = crop.split(/,/).map(&:to_i)
    end

    crop = nil unless crop.is_a?(Array) && crop.size.eql?(4) && crop.all? { |i|
      i.kind_of?(Numeric)
    }

    # can't crop, won't crop
    return if @width.nil? && @height.nil? && crop.nil?

    if crop && @scale != 1.0
      crop = crop.map { |s| (s.to_f * @scale).floor  }
    end

    crop ||= Morandi::Utils.autocrop_coords(@pb.width, @pb.height, @width, @height)

    @pb = Morandi::Utils.apply_crop(@pb, crop[0], crop[1], crop[2], crop[3])
  end


  def apply_filters!
    filter = options['fx']

    case filter
    when 'greyscale'
      op = Morandi::Colourify.new_from_hash('op' => filter)
    when 'sepia', 'bluetone'
      # could also set 'alpha' => (0.85 * 255).to_i
      op = Morandi::Colourify.new_from_hash('op' => filter)
    else
      return
    end
    @pb = op.call(nil, @pb)
  end

  def apply_decorations!
    style, colour = options['border-style'], options['background-style']

    return if style.nil? or style.eql?('none')
    return if colour.eql?('none')
    colour ||= 'black'

    crop = options['crop']
    crop = crop.map { |s| (s.to_f * @scale).floor  } if crop && @scale != 1.0

    op = Morandi::ImageBorder.new_from_hash(data={
      'style' => style,
      'colour' => colour || '#000000',
      'crop' => crop,
      'size' => [@image_width, @image_height],
      'print_size' => [@width, @height],
      'shrink'  => true,
      'border_size' => @scale * config_for('border-size-mm').to_i * 300 / 25.4 # 5mm at 300dpi
    })

    @pb = op.call(nil, @pb)
  end

end
