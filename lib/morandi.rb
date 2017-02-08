require 'morandi/version'
require 'gtk2/base'
require 'cairo'
require 'gdk_pixbuf2'
require 'pixbufutils'
require 'redeye'

require 'morandi/image_processor'
require 'morandi/utils'
require 'morandi/image-ops'
require 'morandi/redeye'

module Morandi
  module_function

  def process(file_in, options, out_file, local_options = {})
    pro = ImageProcessor.new(file_in, options, local_options)
    pro.process!
    pro.write_to_jpeg(out_file)
  end
end
