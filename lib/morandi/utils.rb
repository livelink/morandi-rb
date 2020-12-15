# frozen_string_literal: true

require 'gdk_pixbuf2'

module Morandi
  module Utils
    module_function

    def autocrop_coords(i_width, i_height, width, height)
      return nil unless width

      aspect = width.to_f / height
      iaspect = i_width.to_f / i_height

      if i_height > i_width
        # Portrait image
        # Check whether the aspect ratio is greater or smaller
        # ie. where constraints will hit
        aspect = height.to_f / width
      end

      # Landscape
      if aspect > iaspect
        # Width constraint - aspect-rect wider
        crop_width  = i_width
        crop_height = (crop_width / aspect).to_i
      else
        # Height constraint - aspect-rect wider
        crop_height = i_height
        crop_width  = (crop_height * aspect).to_i
      end

      [
        ((i_width - crop_width) >> 1),
        ((i_height - crop_height) >> 1),
        crop_width,
        crop_height
      ].map(&:to_i)
    end

    def constrain(val, min, max)
      if val < min
        min
      elsif val > max
        max
      else
        val
      end
    end

    def apply_crop(pixbuf, x_coord, y_coord, width, height, fill_col = 0xffffffff)
      if x_coord.negative? ||
         y_coord.negative? ||
         ((x_coord + width) > pixbuf.width) ||
         ((y_coord + height) > pixbuf.height)

        base_pixbuf = GdkPixbuf::Pixbuf.new(GdkPixbuf::Colorspace::RGB, false, 8, width, height)
        base_pixbuf.fill!(fill_col)

        offset_x = [x_coord, 0].max
        offset_y = [y_coord, 0].max
        copy_w = [width, pixbuf.width - offset_x].min
        copy_h = [height, pixbuf.height - offset_y].min

        paste_x = [x_coord, 0].min * -1
        paste_y = [y_coord, 0].min * -1

        copy_w = base_pixbuf.width - paste_x if copy_w + paste_x > base_pixbuf.width
        copy_h = base_pixbuf.height - paste_y if copy_h + paste_y > base_pixbuf.height

        base_pixbuf.composite!(
          pixbuf,
          dest_x: paste_x,
          dest_y: paste_y,
          dest_width: copy_w,
          dest_height: copy_h,
          offset_x: paste_x - offset_x,
          offset_y: paste_y - offset_y,
          scale_x: 1,
          scale_y: y_coord,
          interpolation_type: GdkPixbuf::InterpType::HYPER,
          overall_alpha: 255
        )
        pixbuf = base_pixbuf
      else
        x_coord = constrain(x_coord, 0, pixbuf.width)
        y_coord = constrain(y_coord, 0, pixbuf.height)
        width = constrain(width, 1, pixbuf.width - x_coord)
        height = constrain(height, 1, pixbuf.height - y_coord)

        pixbuf = pixbuf.subpixbuf(x_coord, y_coord, width, height)
      end
      pixbuf
    end
  end
end

module GdkPixbuf
  class Pixbuf
    InterpType = GdkPixbuf::InterpType unless defined?(::Gdk::Pixbuf::InterpType)

    def scale_max(max_size, interp = GdkPixbuf::Pixbuf::InterpType::BILINEAR, _max_scale = 1.0)
      mul = (max_size / [width, height].max.to_f)
      mul = [1.0, mul].min
      scale(width * mul, height * mul, interp)
    end
  end
end

module Cairo
  class ImageSurface
    def to_pixbuf
      loader = GdkPixbuf::PixbufLoader.new
      io = StringIO.new
      write_to_png(io)
      io.rewind
      loader.last_write(io.read)
      loader.pixbuf
    end
  end
end
