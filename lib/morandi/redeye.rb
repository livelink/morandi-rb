# frozen_string_literal: true

module Morandi
  module RedEye
    # The parameter determines how many reddish pixels needs to be in the area to consider it a valid red eye
    # The reason for its existence is to prevent the situations when the bigger red area causes an excessive correction
    # e.g. continuous red eyeglasses frame or sunburnt person's skin around eyes forming an area
    RED_AREA_DENSITY_THRESHOLD = 0.3

    module TapRedEye
      module_function

      def tap_on(pixbuf, x_coord, y_coord)
        n = ([pixbuf.height, pixbuf.width].max / 10)
        x1  = [x_coord - n, 0].max
        x2  = [x_coord + n, pixbuf.width].min
        y1  = [y_coord - n, 0].max
        y2  = [y_coord + n, pixbuf.height].min
        return pixbuf unless (x1 >= 0) && (x2 > x1) && (y1 >= 0) && (y2 > y1)

        red_eye = MorandiNative::RedEye.new(pixbuf, x1, y1, x2, y2)

        sensitivity = 2
        blobs = red_eye.identify_blobs(sensitivity).reject do |region|
          region.noPixels < 4 || !region.squareish?(0.5, RED_AREA_DENSITY_THRESHOLD)
        end

        sorted_blobs = blobs.sort_by do |region|
          region.area_min_x = x1
          region.area_min_y = y1
        end

        blob = sorted_blobs.last
        red_eye.correct_blob(blob.id) if blob
        red_eye.pixbuf
      end
    end
  end
end

module MorandiNative
  module RedEye
    class Region
      attr_accessor :area_min_x, :area_min_y

      def centre
        [@area_min_x.to_i + ((maxX + minX) >> 1),
         @area_min_y.to_i + ((maxY + minY) >> 1)]
      end

      # Pythagorean
      def distance_from(x_coord, y_coord)
        cx, cy = centre

        dx = cx - x_coord
        dy = cy - y_coord

        Math.sqrt((dx**2) + (dy**2))
      end
    end
  end
end
