# frozen_string_literal: true

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
        base_pixbuf = GdkPixbuf::Pixbuf.new(GdkPixbuf::Colorspace::RGB, false, 8, w, h)
        base_pixbuf.fill!(fill_col)

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

        base_pixbuf.composite!(
          pixbuf,
          dest_x: paste_x,
          dest_y: paste_y,
          dest_width: copy_w,
          dest_height: copy_h,
          offset_x: paste_x - offset_x,
          offset_y: paste_y - offset_y,
          scale_x: 1,
          scale_y: y,
          interpolation_type: GdkPixbuf::InterpType::HYPER,
          overall_alpha: 255
        )
        pixbuf = base_pixbuf
      else
        x = constrain(x, 0, pixbuf.width)
        y = constrain(y, 0, pixbuf.height)
        w = constrain(w, 1, pixbuf.width - x)
        h = constrain(h, 1, pixbuf.height - y)

        pixbuf = pixbuf.subpixbuf(x, y, w, h)
      end
      pixbuf
    end
  end
end

class GdkPixbuf::Pixbuf
  unless defined?(::Gdk::Pixbuf::InterpType)
    InterpType = GdkPixbuf::InterpType
  end

  def scale_max(max_size, interp = GdkPixbuf::Pixbuf::InterpType::BILINEAR, max_scale = 1.0)
    mul = (max_size / [width,height].max.to_f)
    mul = [max_scale = 1.0,mul].min
    scale(width * mul, height * mul, interp)
  end
end

class Cairo::ImageSurface
  def to_pixbuf
    loader = GdkPixbuf::PixbufLoader.new
    io = StringIO.new
    write_to_png(io)
    io.rewind
    loader.last_write(io.read)
    loader.pixbuf
  end
end
