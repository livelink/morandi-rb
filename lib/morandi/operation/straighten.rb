# frozen_string_literal: true

require 'morandi/image_operation'

module Morandi
  module Operation
    # Straighten operation
    # Does a small (ie. not 90,180,270 deg) rotation and zooms to avoid cropping
    # @!visibility private
    class Straighten < ImageOperation
      attr_accessor :angle

      def call(_image, pixbuf)
        return pixbuf if angle.zero?

        rotation_value_rad = angle * (Math::PI / 180)

        ratio = pixbuf.width.to_f / pixbuf.height
        rh = pixbuf.height / ((ratio * Math.sin(rotation_value_rad.abs)) + Math.cos(rotation_value_rad.abs))
        scale = pixbuf.height / rh.to_f.abs

        a_ratio = pixbuf.height.to_f / pixbuf.width
        a_rh = pixbuf.width / ((a_ratio * Math.sin(rotation_value_rad.abs)) + Math.cos(rotation_value_rad.abs))
        a_scale = pixbuf.width / a_rh.to_f.abs

        scale = a_scale if a_scale > scale

        create_pixbuf_from_image_surface(:rgb24, pixbuf.width, pixbuf.height) do |cr|
          cr.translate(pixbuf.width / 2.0, pixbuf.height / 2.0)
          cr.rotate(rotation_value_rad)
          cr.scale(scale, scale)
          cr.translate(pixbuf.width / -2.0, pixbuf.height / - 2.0)
          cr.set_source_pixbuf(pixbuf)

          cr.rectangle(0, 0, pixbuf.width, pixbuf.height)
          cr.paint(1.0)
        end
      end
    end
  end
end
