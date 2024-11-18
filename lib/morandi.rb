# frozen_string_literal: true

require 'morandi/version'
require 'morandi_native'

require 'morandi/cairo_ext'
require 'morandi/pixbuf_ext'
require 'morandi/errors'
require 'morandi/image_processor'
require 'morandi/vips_image_processor'
require 'morandi/redeye'
require 'morandi/crop_utils'

# Morandi namespace should contain all the functionality of the gem
module Morandi
  module_function

  # The main entry point for the library
  #
  # @param source [String|GdkPixbuf::Pixbuf] source image
  # @param [Hash] options The options describing expected processing to perform
  # @option options [Integer] 'brighten' Change image brightness (-20..20)
  # @option options [Float] 'gamma' Gamma correct image
  # @option options [Integer] 'contrast' Change image contrast (-20..20)
  # @option options [Integer] 'sharpen' Sharpen (1..5) / Blur (-1..-5)
  # @option options [Array[[Integer,Integer],...]] 'redeye' Apply redeye correction at point
  # @option options [Integer] 'angle' Rotate image clockwise by multiple of 90 (0, 90, 180, 270)
  # @option options [Array[Integer,Integer,Integer,Integer]] 'crop' Crop image (x, y, width, height)
  # @option options [String] 'fx' Apply colour filters ('greyscale', 'sepia', 'bluetone')
  # @option options [String] 'border-style' Set border style ('square', 'retro')
  # @option options [String] 'background-style' Set border colour ('retro', 'black', 'white')
  # @option options [Integer] 'quality' (97) Set JPG compression value (1 to 100)
  # @option options [Integer] 'output.max' Downscales the image to fit within the square of given size before
  #                                        processing to limit the required resources
  # @option options [Integer] 'output.width' Sets desired width of resulting image
  # @option options [Integer] 'output.height' Sets desired height of resulting image
  # @option options [TrueClass|FalseClass] 'image.auto-crop' (true) If the output dimensions are set and this is true,
  #                                                                image is cropped automatically to the desired
  #                                                                dimensions.
  # @option options [TrueClass|FalseClass] 'output.limit' (false) If the output dimensions are defined and this is true,
  #                                                              the output image is scaled down to fit within square of
  #                                                              size of the longer edge (ignoring shorter dimension!)
  # @param target_path [String] target location for image
  # @param local_options [Hash] Hash of options other than desired transformations
  # @option local_options [String] 'path.icc' A path to store the input after converting to sRGB colour space
  # @options local_options [String] 'processor' ('pixbuf') Name of the image processing library ('pixbuf', 'vips')
  def process(source, options, target_path, local_options = {})
    case local_options['processor']
    when 'vips'
      # Cache saves time in expense of RAM when performing the same processing multiple times
      # Cache is also created for files based on their names, which can lead to leaking files data, so in terms
      # of security it feels prudent to disable it. Latest libvips supports "revalidate" option to prevent that risk
      cache_max = 0
      concurrency = 2 # Hardcoding to 2 for now to maintain some balance between resource usage and performance
      VipsImageProcessor.with_global_options(cache_max: cache_max, concurrency: concurrency) do
        VipsImageProcessor.new(source, options).write_to_jpeg(target_path)
      end
    else
      ImageProcessor.new(source, options, local_options).tap(&:result).write_to_jpeg(target_path)
    end
  end
end
