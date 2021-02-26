# frozen_string_literal: true

require 'cairo'
require 'gdk_pixbuf_cairo'
require 'pango'

module Morandi
  # Rounded rectangle function for photo borders
  module CairoExt
    module_function

    def rounded_rectangle(cr, x1, y1, x2, y2, x_radius = 4, y_radius = nil)
      width = x2 - x1
      height = y2 - y1
      y_radius ||= x_radius

      x_radius = [x_radius, width / 2].min
      y_radius = [y_radius, height / 2].min

      xr1 = x_radius
      xr2 = x_radius / 2.0
      yr1 = y_radius
      yr2 = y_radius / 2.0

      cr.new_path
      cr.move_to(x1 + xr1, y1)
      cr.line_to(x2 - xr1, y1)
      cr.curve_to(x2 - xr2, y1, x2, y1 + yr2, x2, y1 + yr1)
      cr.line_to(x2, y2 - yr1)
      cr.curve_to(x2, y2 - yr2, x2 - xr2, y2, x2 - xr1, y2)
      cr.line_to(x1 + xr1, y2)
      cr.curve_to(x1 + xr2, y2, x1, y2 - yr2, x1, y2 - yr1)
      cr.line_to(x1, y1 + yr1)
      cr.curve_to(x1, y1 + yr2, x1 + xr2, y1, x1 + xr1, y1)
      cr.close_path
    end
  end
end

# Monkey patch Cairo::Context
module Cairo
  # Add Cairo::Context#set_source_pixbuf without gtk2 depdendency
  class Context
    def set_source_pixbuf(pixbuf, x = 0, y = 0)
      set_source(pixbuf.to_cairo_image_surface, x, y)
    end
  end

  # Add ImageSurface.to_gdk_pixbuf
  # for converting back to pixbuf without exporting as PNG
  class ImageSurface
    def to_gdk_pixbuf
      GdkPixbufCairo.surface_to_pixbuf(self)
    end
  end
end
