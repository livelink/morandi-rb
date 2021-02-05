# frozen_string_literal: true

require 'morandi/version'
require 'cairo'
require 'gdk_pixbuf2'
require 'morandi_native'

require 'morandi/image_processor'
require 'morandi/utils'
require 'morandi/image_ops'
require 'morandi/redeye'

module Morandi
  module_function

  def process(file_in, options, file_out, local_options = {})
    pro = ImageProcessor.new(file_in, options, local_options)
    pro.process!
    pro.write_to_jpeg(file_out)
  end
end
