# frozen_string_literal: true

require 'colorscore'

module Morandi
  # Base Image Op class
  # @!visibility private
  class ImageOperation
    class << self
      def new_from_hash(hash)
        op = allocate
        hash.each_pair do |key, val|
          op.instance_variable_set("@#{key}", val) if op.respond_to?(key.intern)
        end
        op
      end
    end
  end

  # Straighten operation
  # Does a small (ie. not 90,180,270 deg) rotation and zooms to avoid cropping
  # @!visibility private
  class Straighten < ImageOperation
    attr_accessor :angle

    def call(_image, pixbuf)
      return pixbuf if @angle.zero?

      surface = Cairo::ImageSurface.new(:rgb24, pixbuf.width, pixbuf.height)

      rotation_value_rad = @angle * (Math::PI / 180)

      ratio = pixbuf.width.to_f / pixbuf.height
      rh = pixbuf.height / ((ratio * Math.sin(rotation_value_rad.abs)) + Math.cos(rotation_value_rad.abs))
      scale = pixbuf.height / rh.to_f.abs

      a_ratio = pixbuf.height.to_f / pixbuf.width
      a_rh = pixbuf.width / ((a_ratio * Math.sin(rotation_value_rad.abs)) + Math.cos(rotation_value_rad.abs))
      a_scale = pixbuf.width / a_rh.to_f.abs

      scale = a_scale if a_scale > scale

      cr = Cairo::Context.new(surface)

      cr.translate(pixbuf.width / 2.0, pixbuf.height / 2.0)
      cr.rotate(rotation_value_rad)
      cr.scale(scale, scale)
      cr.translate(pixbuf.width / -2.0, pixbuf.height / - 2.0)
      cr.set_source_pixbuf(pixbuf)

      cr.rectangle(0, 0, pixbuf.width, pixbuf.height)
      cr.paint(1.0)
      final_pb = surface.to_gdk_pixbuf
      cr.destroy
      surface.destroy
      final_pb
    end
  end

  # Image Border operation
  # Supports retro (rounded) and square borders
  # Background colour (ie. border colour) can be white, black, dominant (ie. from image)
  # @!visibility private
  class ImageBorder < ImageOperation
    attr_accessor :style, :colour, :crop, :size, :print_size, :shrink, :border_size

    def call(_image, pixbuf)
      return pixbuf unless %w[square retro].include? @style

      create_pixbuf_from_image_surface(:rgb24, pixbuf.width, pixbuf.height) do |cr|
        if @crop && ((@crop[0]).negative? || (@crop[1]).negative?)
          img_width = size[0]
          img_height = size[1]
        else
          img_width = pixbuf.width
          img_height = pixbuf.height
        end

        @border_scale = [img_width, img_height].max.to_f / print_size.max.to_i

        draw_background(cr, img_height, img_width, pixbuf)

        x = border_width
        y = border_width

        # This biggest impact will be on the smallest side, so to avoid white
        # edges between photo and border scale by the longest changed side.
        longest_side = [pixbuf.width, pixbuf.height].max.to_f

        # Should be less than 1
        pb_scale = (longest_side - (border_width * 2)) / longest_side

        if @crop && ((@crop[0]).negative? || (@crop[1]).negative?)
          x -= @crop[0]
          y -= @crop[1]
        end

        draw_pixbuf(pixbuf, cr, img_height, img_width, pb_scale, x, y)
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

    # Width is proportional to output size
    def border_width
      @border_size * @border_scale
    end

    def draw_pixbuf(pixbuf, cr, img_height, img_width, pb_scale, x, y)
      case style
      when 'retro'
        Morandi::CairoExt.rounded_rectangle(cr, x, y,
                                            img_width + x - (border_width * 2),
                                            img_height + y - (border_width * 2), border_width)
      when 'square'
        cr.rectangle(x, y, img_width - (border_width * 2), img_height - (border_width * 2))
      end
      cr.clip

      if @shrink
        cr.translate(border_width, border_width)
        cr.scale(pb_scale, pb_scale)
      end
      cr.set_source_pixbuf(pixbuf)
      cr.rectangle(0, 0, pixbuf.width, pixbuf.height)

      cr.paint(1.0)
    end

    def draw_background(cr, img_height, img_width, pixbuf)
      cr.save do
        cr.translate(-@crop[0], -@crop[1]) if @crop && ((@crop[0]).negative? || (@crop[1]).negative?)

        cr.save do
          cr.set_operator :source
          cr.set_source_rgb 1, 1, 1
          cr.paint

          cr.rectangle(0, 0, img_width, img_height)
          case colour
          when 'dominant'
            pixbuf.scale_max(400).save(fn = "/tmp/hist-#{$PROCESS_ID}.#{Time.now.to_i}", 'jpeg')
            histogram = Colorscore::Histogram.new(fn)
            FileUtils.rm_f(fn)
            col = histogram.scores.first[1]
            cr.set_source_rgb col.red / 256.0, col.green / 256.0, col.blue / 256.0
          when 'retro'
            cr.set_source_rgb 1, 1, 0.8
          when 'black'
            cr.set_source_rgb 0, 0, 0
          else
            cr.set_source_rgb 1, 1, 1
          end
          cr.fill
        end
      end
    end
  end

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
