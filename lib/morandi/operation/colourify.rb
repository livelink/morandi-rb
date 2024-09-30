# frozen_string_literal: true

require 'morandi/image_operation'

module Morandi
  module Operation
    # Colourify Operation
    # Apply tint to image with variable strength
    # Supports filter, alpha
    class Colourify < ImageOperation
      attr_reader :filter

      def alpha
        @alpha || 255
      end

      def sepia(pixbuf)
        MorandiNative::PixbufUtils.tint(pixbuf, 25, 5, -25, alpha)
      end

      def bluetone(pixbuf)
        MorandiNative::PixbufUtils.tint(pixbuf, -10, 5, 25, alpha)
      end

      def null(pixbuf)
        pixbuf
      end
      alias full null # WebKiosk
      alias colour null # WebKiosk

      def greyscale(pixbuf)
        MorandiNative::PixbufUtils.tint(pixbuf, 0, 0, 0, alpha)
      end
      alias bw greyscale # WebKiosk

      def call(_image, pixbuf)
        if @filter && respond_to?(@filter)
          __send__(@filter, pixbuf)
        else
          pixbuf # Default is nothing
        end
      end
    end
  end
end
