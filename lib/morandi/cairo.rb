require 'gdk_pixbuf_cairo'

class Cairo::Context
  def set_source_pixbuf(pixbuf, x=0, y=0)
    set_source(GdkPixbufCairo.pixbuf_to_surface(pixbuf), x, y)
  end
end

class Cairo::ImageSurface
  def to_gdk_pixbuf
    GdkPixbufCairo.surface_to_pixbuf(self)
  end
end

class GdkPixbuf::Pixbuf
  def to_cairo_image_surface
    GdkPixbufCairo.pixbuf_to_surface(self)
  end
end