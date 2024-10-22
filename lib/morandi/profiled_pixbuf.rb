# frozen_string_literal: true

require 'gdk_pixbuf2'
require 'morandi/srgb_conversion'

module Morandi
  # ProfiledPixbuf is a descendent of GdkPixbuf::Pixbuf with ICC support.
  # It attempts to load an image using jpegicc/littlecms to ensure that it is sRGB.
  # NOTE: pixbuf supports colour profiles, but it requires an explicit icc-profile option to embed it when saving file
  class ProfiledPixbuf < GdkPixbuf::Pixbuf
    def initialize(path, local_options, max_size_px = nil)
      @local_options = local_options

      path = srgb_path(path) || path

      if max_size_px
        super(file: path, width: max_size_px, height: max_size_px)
      else
        super(file: path)
      end
    end

    private

    def srgb_path(original_path)
      Morandi::SrgbConversion.perform(original_path, target_path: @local_options['path.icc'])
    end
  end
end
