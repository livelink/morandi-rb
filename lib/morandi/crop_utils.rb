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

      # TODO: this looks wrong - typically relative aspect ratios matter more
      # than whether this is portrait or landscape
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
          scale_y: 1,
          interpolation_type: :hyper,
          overall_alpha: 255
        )
        pixbuf = base_pixbuf
      else
        x_coord = x_coord.clamp(0, pixbuf.width)
        y_coord = y_coord.clamp(0, pixbuf.height)
        width = width.clamp(1, pixbuf.width - x_coord)
        height = height.clamp(1, pixbuf.height - y_coord)

        pixbuf = pixbuf.subpixbuf(x_coord, y_coord, width, height)
      end
      pixbuf
    end

    def apply_crop_vips(img, x_coord, y_coord, width, height)
      if x_coord.negative? ||
         y_coord.negative? ||
         ((x_coord + width) > img.width) ||
         ((y_coord + height) > img.height)

        extract_area_x = [0, x_coord].max
        extract_area_y = [0, y_coord].max
        area_to_copy = img.extract_area(extract_area_x, extract_area_y, img.width - extract_area_x,
                                        img.height - extract_area_y)

        fill_colour = [255, 255, 255]
        pixel = (Vips::Image.black(1, 1).colourspace(:srgb) + fill_colour).cast(img.format)
        canvas = pixel.embed 0, 0, width, height, extend: :copy

        cropped = canvas.composite(area_to_copy, :over, x: [-x_coord, 0].max,
                                                        y: [-y_coord, 0].max,
                                                        compositing_space: area_to_copy.interpretation)

        # Because image is drawn on an opaque white, alpha doesn't matter at this point anyway, so let's strip the
        # alpha channel from the output. According to #composite docs, the resulting image always has alpha channel,
        # but I added a guard to avoid regressions if that ever changes.
        cropped = cropped.extract_band(0, n: cropped.bands - 1) if cropped.has_alpha?
        cropped
      else
        x_coord = x_coord.clamp(0, img.width)
        y_coord = y_coord.clamp(0, img.height)
        width = width.clamp(1, img.width - x_coord)
        height = height.clamp(1, img.height - y_coord)

        img.crop(x_coord, y_coord, width, height)
      end
    end
  end
end
