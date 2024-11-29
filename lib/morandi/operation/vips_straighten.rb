# frozen_string_literal: true

module Morandi
  module Operation
    # Straighten operation
    # Does a small (ie. not 90,180,270 deg) rotation and zooms to avoid cropping
    # @!visibility private
    class VipsStraighten < ImageOperation
      # Colour for filling background post-rotation. It can bleed into the edge pixels during resize.
      # Setting it to gray minimises the average impact
      ROTATION_BACKGROUND_FILL_COLOUR = 127
      ROTATION_BACKGROUND_FILL_ALPHA = 255

      def self.rotation_background_fill_colour(channels_count:, alpha:)
        return [ROTATION_BACKGROUND_FILL_COLOUR] * channels_count unless alpha # Eg [127, 127, 127] for RGB

        # Eg [127, 127, 127, 255] for RGBA
        ([ROTATION_BACKGROUND_FILL_COLOUR] * (channels_count - 1)) + [ROTATION_BACKGROUND_FILL_ALPHA]
      end

      attr_accessor :angle

      def call(img)
        return img if angle.zero?

        original_width = img.width
        original_height = img.height

        # It is possible to first rotate, then fetch width/height of resulting image to calculate scale,
        # but that would make us lose precision which degrades cropping accuracy
        rotation_value_rad = angle * (Math::PI / 180)
        post_rotation_bounding_box_width = (img.height.to_f * Math.sin(rotation_value_rad).abs) +
                                           (img.width.to_f * Math.cos(rotation_value_rad).abs)
        post_rotation_bounding_box_height = (img.width.to_f * Math.sin(rotation_value_rad).abs) +
                                            (img.height.to_f * Math.cos(rotation_value_rad).abs)

        # Calculate scaling required to fit the original width/height within rotated image without including background
        scale = [post_rotation_bounding_box_width / original_width,
                 post_rotation_bounding_box_height / original_height].max

        background_fill_colour = self.class.rotation_background_fill_colour(channels_count: img.bands,
                                                                            alpha: img.has_alpha?)
        img = img.similarity(angle: angle, scale: scale, background: background_fill_colour)

        # Better precision than img.width/img.height due to fractions preservation
        post_scale_bounding_box_width = post_rotation_bounding_box_width * scale
        post_scale_bounding_box_height = post_rotation_bounding_box_height * scale

        width_diff = post_scale_bounding_box_width - original_width
        height_diff = post_scale_bounding_box_height - original_height

        # Round to nearest integer to reduce risk of ROTATION_BACKGROUND_FILL_COLOUR being visible in the corner
        crop_x = (width_diff / 2).round
        crop_y = (height_diff / 2).round

        img.crop(crop_x, crop_y, original_width, original_height)
      end
    end
  end
end
