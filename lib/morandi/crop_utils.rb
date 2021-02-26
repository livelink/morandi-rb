# frozen_string_literal: true

require 'gdk_pixbuf2'

module Morandi
  # Utility functions relating to cropping
  module CropUtils
    module_function

    def autocrop_coords(pixbuf_width, pixbuf_height, target_width, target_height)
      return nil unless target_width

      aspect = target_width.to_f / target_height
      pixbuf_aspect = pixbuf_width.to_f / pixbuf_height

      if pixbuf_height > pixbuf_width
        # Portrait image
        # Check whether the aspect ratio is greater or smaller
        # ie. where constraints will hit
        aspect = target_height.to_f / target_width
      end

      # Landscape
      if aspect > pixbuf_aspect
        # Width constraint - aspect-rect wider
        crop_width  = pixbuf_width
        crop_height = (crop_width / aspect).to_i
      else
        # Height constraint - aspect-rect wider
        crop_height = pixbuf_height
        crop_width  = (crop_height * aspect).to_i
      end

      [
        ((pixbuf_width - crop_width) >> 1),
        ((pixbuf_height - crop_height) >> 1),
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

        base_pixbuf = GdkPixbuf::Pixbuf.new(
          colorspace: GdkPixbuf::Colorspace::RGB,
          has_alpha: false,
          bits_per_sample: 8,
          width: width,
          height: height
        )
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
          interpolation_type: :hyper,
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
