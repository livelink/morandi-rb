# frozen_string_literal: true

require 'morandi/version'
require 'morandi_native'

require 'morandi/cairo_ext'
require 'morandi/pixbuf_ext'
require 'morandi/errors'
require 'morandi/image_processor'
require 'morandi/redeye'
require 'morandi/crop_utils'

# Morandi namespace should contain all the functionality of the gem
module Morandi
  module_function

  # The main entry point for the libray
  #
  # @param source [String|GdkPixbuf::Pixbuf] source image
  # @param options [Hash]
  # @param target_path [String] target location for image
  # @param local_options [Hash]
  #
  # Settings Key | Values | Description
  # -------------|--------|---------------
  # brighten     | Integer -20..20 | Change image brightness
  # gamma        | Float  | Gamma correct image
  # contrast     | Integer -20..20  | Change image contrast
  # sharpen      | Integer -5..5  | Sharpen / Blur (negative value)
  # redeye       | Array[[Integer,Integer],...]  | Apply redeye correction at point
  # angle        | Integer 0,90,180,270  | Rotate image
  # crop         | Array[Integer,Integer,Integer,Integer] | Crop image
  # fx           | String greyscale,sepia,bluetone | Apply colour filters
  # border-style  | String square,retro | Set border style
  # background-style  | String retro,black,white | Set border colour
  # quality       | String '1'..'100' | Set JPG compression value, defaults to 97%
  def process(source, options, target_path, local_options = {})
    pro = ImageProcessor.new(source, options, local_options)
    pro.result
    pro.write_to_jpeg(target_path)
  end
end
