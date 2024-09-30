# frozen_string_literal: true

module Morandi
  # Base Image Op class
  # @!visibility private
  class ImageOperation
    class << self
      def new_from_hash(hash)
        op = allocate
        hash.each_pair do |key, val|
          op.respond_to?(key.intern) && op.instance_variable_set("@#{key}", val)
        end
        op
      end
    end

    private

    def create_pixbuf_from_image_surface(type, width, height)
      surface = Cairo::ImageSurface.new(type, width, height)
      cr = Cairo::Context.new(surface)

      yield(cr)

      final_pb = surface.to_gdk_pixbuf
      cr.destroy
      surface.destroy
      final_pb
    end
  end
end
