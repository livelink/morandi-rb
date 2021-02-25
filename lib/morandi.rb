# frozen_string_literal: true

require 'morandi/version'
require 'morandi_native'

require 'morandi/cairo_ext'
require 'morandi/pixbuf_ext'
require 'morandi/image_processor'
require 'morandi/image_operation'
require 'morandi/redeye'
require 'morandi/crop_utils'

# Morandi namespace should contain all the functionality of the gem
module Morandi
  module_function

  def process(file_in, options, file_out, local_options = {})
    pro = ImageProcessor.new(file_in, options, local_options)
    pro.result
    pro.write_to_jpeg(file_out)
  end
end
