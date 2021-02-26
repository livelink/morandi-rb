# frozen_string_literal: true

module ColourHelper
  def generate_test_image(at_file_path, width = 600, height = 300)
    system(
      'convert',
      '-size',
      "#{width}x#{height}",
      '-seed',
      '5432',
      'plasma:red-blue',
      'pattern:checkerboard', '-gravity', 'center', '-geometry', "+#{width * 3 / 4},+0", '-composite',
      at_file_path
    )
  end

  def solid_colour_image(width, height, colour = 0x000000ff)
    pb = GdkPixbuf::Pixbuf.new(colorspace: GdkPixbuf::Colorspace::RGB,
                               has_alpha: false,
                               bits_per_sample: 8,
                               width: width,
                               height: height)
    pb.fill!(colour)
    pb
  end

  def crude_average_colour(pixbuf)
    get_pixels = lambda do |pb|
      pb.pixels.each_slice(pb.rowstride).map do |row|
        row.each_slice(pb.n_channels).to_a[0...pb.width]
      end.to_a[0...pb.height].flatten(1)
    end
    avg_color = lambda do |pixels|
      list = pixels.inject([0, 0, 0]) do |(br, bg, bb), (r, g, b)|
        [br + r, bg + g, bb + b]
      end
      list.map { |a| (a / pixels.size.to_f).to_i }
    end
    avg_color.call(get_pixels.call(pixbuf))
  end
end
