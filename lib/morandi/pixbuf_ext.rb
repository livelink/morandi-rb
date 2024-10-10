# frozen_string_literal: true

require 'gdk_pixbuf2'

# GdkPixbuf module / hierachy
module GdkPixbuf
  # Add #to_cairo_image_surface for converting pixels to Cairo::ImageSurface format (RGBA->ARGB)
  class Pixbuf
    def to_cairo_image_surface
      GdkPixbufCairo.pixbuf_to_surface(self)
    end

    # Proportionally scales down the image so that it fits within max_size*max_size square
    def scale_max(max_size, interp = GdkPixbuf::InterpType::BILINEAR, _max_scale = 1.0)
      mul = (max_size / [width, height].max.to_f)
      mul = [1.0, mul].min
      scale(width * mul, height * mul, interp)
    end
  end
end
