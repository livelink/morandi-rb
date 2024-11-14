# frozen_string_literal: true

module ColourHelper
  def generate_test_image_plasma_checkers(at_file_path, width: 600, height: 300)
    fill = [
      ['plasma:red-blue'],
      ['pattern:checkerboard', '-gravity', 'center', '-geometry', "+#{width * 3 / 4},+0", '-composite']
    ]
    generate_test_image(at_file_path, fill: fill, width: width, height: height)
  end

  def generate_test_image_greyscale(at_file_path, width: 600, height: 300)
    generate_test_image(at_file_path, fill: 'gradient:white-black', width: width, height: height)
  end

  def generate_test_image(at_file_path, fill:, width: 600, height: 300)
    fill = Array(fill).flatten

    generate_image_options = ['convert', '-size', "#{width}x#{height}", '-seed', '5432', *fill, at_file_path]
    system(*generate_image_options) || raise("Failed to generate image.\nCommand: #{generate_image_options.join(' ')}")
  end

  def generate_test_image_solid(at_file_path, width: 600, height: 300, colour: '#000000')
    generate_test_image(at_file_path, width: width, height: height, fill: "canvas:#{colour}")
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
