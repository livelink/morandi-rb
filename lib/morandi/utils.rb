require 'gdk_pixbuf2'

module Morandi
  module Utils
    module_function
    def autocrop_coords(iw, ih, width, height)
      return nil unless width
      aspect = width.to_f / height.to_f
      iaspect = iw.to_f / ih.to_f

      if ih > iw
        # Portrait image
        # Check whether the aspect ratio is greater or smaller
        # ie. where constraints will hit
        aspect = height.to_f / width.to_f
      end

      # Landscape
      if aspect > iaspect
        # Width constraint - aspect-rect wider
        crop_width  = iw
        crop_height = (crop_width / aspect).to_i
      else
        # Height constraint - aspect-rect wider
        crop_height = ih
        crop_width  = (crop_height * aspect).to_i
      end

      [
        ((iw - crop_width)>>1),
        ((ih - crop_height)>>1),
        crop_width,
        crop_height
      ].map { |i| i.to_i }
    end

    def constrain(val,min,max)
      if val < min
        min
      elsif val > max
        max
      else
        val
      end
    end

    def apply_crop(pixbuf, x, y, w, h, fill_col = 0xffffffff)
      if (x < 0) or (y < 0) || ((x+w) > pixbuf.width) || ((y+h) > pixbuf.height)
        #tw, th = [w-x,w].max, [h-y,h].max
        base_pixbuf = Gdk::Pixbuf.new(Gdk::Pixbuf::ColorSpace::RGB, false, 8, w, h)
        base_pixbuf.fill!(fill_col)
        dest_x = [x, 0].min
        dest_y = [y, 0].min
        #src_x = [x,0].max
        #src_y = [y,0].max
        dest_x = [-x,0].max
        dest_y = [-y,0].max

        #if x < 0
        #else
        #end
        #if y < 0
        #  dest_h = [h-dest_y, pixbuf.height, base_pixbuf.height-dest_y].min
        #else
        #	dest_h = [h,pixbuf.height].min
        #end
        #  dest_w  = [w-dest_x, pixbuf.width, base_pixbuf.width-dest_x].min

        offset_x = [x,0].max
        offset_y = [y,0].max
        copy_w = [w, pixbuf.width - offset_x].min
        copy_h = [h, pixbuf.height - offset_y].min

        paste_x = [x, 0].min * -1
        paste_y = [y, 0].min * -1

        if copy_w + paste_x > base_pixbuf.width
          copy_w = base_pixbuf.width - paste_x
        end
        if copy_h + paste_y > base_pixbuf.height
          copy_h = base_pixbuf.height - paste_y
        end

        args = [pixbuf, paste_x, paste_y, copy_w, copy_h, paste_x - offset_x, paste_y - offset_y, 1, 1, Gdk::Pixbuf::INTERP_HYPER, 255]
        #p args
        base_pixbuf.composite!(*args)
        pixbuf = base_pixbuf
      else
        x = constrain(x, 0, pixbuf.width)
        y = constrain(y, 0, pixbuf.height)
        w = constrain(w, 1, pixbuf.width - x)
        h = constrain(h, 1, pixbuf.height - y)
        #p [pixbuf, x, y, w, h]
        pixbuf = Gdk::Pixbuf.new(pixbuf, x, y, w, h)
      end
      pixbuf
    end
  end
end

class Gdk::Pixbuf
  unless defined?(::Gdk::Pixbuf::InterpType)
    InterpType = GdkPixbuf::InterpType
  end

  def scale_max(max_size, interp = Gdk::Pixbuf::InterpType::BILINEAR, max_scale = 1.0)
    mul = (max_size / [width,height].max.to_f)
    mul = [max_scale = 1.0,mul].min
    scale(width * mul, height * mul, interp)
  end
end

class Cairo::ImageSurface
  def to_pixbuf
    loader = Gdk::PixbufLoader.new
    io = StringIO.new
    write_to_png(io)
    io.rewind
    loader.last_write(io.read)
    loader.pixbuf
  end
end
