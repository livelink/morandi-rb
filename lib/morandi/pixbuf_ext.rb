# frozen_string_literal: true

require 'gdk_pixbuf2'

# GdkPixbuf module / hierachy
module GdkPixbuf
  # Add #to_cairo_image_surface for converting pixels to Cairo::ImageSurface format (RGBA->ARGB)
  class Pixbuf
    InterpType = GdkPixbuf::InterpType unless defined?(::Gdk::Pixbuf::InterpType)

    def to_cairo_image_surface
      GdkPixbufCairo.pixbuf_to_surface(self)
    end

    def scale_max(max_size, interp = GdkPixbuf::Pixbuf::InterpType::BILINEAR, _max_scale = 1.0)
      mul = (max_size / [width, height].max.to_f)
      mul = [1.0, mul].min
      scale(width * mul, height * mul, interp)
    end
  end
end
