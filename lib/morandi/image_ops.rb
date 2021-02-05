# frozen_string_literal: true

require 'pango'
require 'colorscore'
require 'gdk3'
require 'gdk3/loader'
Gdk::Loader.new(Gdk).load

module Morandi
  class ImageOp
    class << self
      def new_from_hash(hash)
        op = allocate
        hash.each_pair do |key, val|
          op.instance_variable_set("@#{key}", val) if op.respond_to?(key.intern)
        end
        op
      end
    end
    def initialize; end

    def priority
      100
    end
  end

  class Crop < ImageOp
    attr_accessor :area

    def initialize(area = nil)
      super()
      @area = area
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

    def call(_image, pixbuf)
      if @area && !@area.width.zero? && !@area.height.zero?
        # NB: Cheap - fast & shares memory
        GdkPixbuf::Pixbuf.new(pixbuf, @area.x, @area.y,
                        @area.width, @area.height)
      else
        pixbuf
      end
    end
  end

  class Rotate < ImageOp
    attr_accessor :angle

    def initialize(angle = 0)
      super()
      @angle = angle
    end

    def call(_image, pixbuf)
      if @angle.zero?
        pixbuf
      else
        case @angle
        when 0, 90, 180, 270
          PixbufUtils.rotate(pixbuf, @angle)
        else
          raise 'Not a valid angle'
        end
      end
    end
  end

  class Straighten < ImageOp
    attr_accessor :angle

    def initialize(angle = 0)
      super()
      @angle = angle
    end

    def call(_image, pixbuf)
      if @angle.zero?
        pixbuf
      else
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
        final_pb = surface.to_pixbuf
        cr.destroy
        surface.destroy
        final_pb
      end
    end
  end

  class ImageCaption < ImageOp
    attr_accessor :text

    def font
      @font || "Open Sans Condensed Light #{([@pixbuf.width, @pixbuf.height].max / 80.0).to_i}"
    end

    def position
      @position ||
        (@pixbuf ? ([[@pixbuf.width, @pixbuf.height].max / 20] * 2) : [100, 100])
    end

    def call(_image, pixbuf)
      @pixbuf = pixbuf
      surface = Cairo::ImageSurface.new(:rgb24, pixbuf.width, pixbuf.height)
      cr = Cairo::Context.new(surface)

      cr.save do
        cr.set_source_pixbuf(pixbuf)
        cr.paint(1.0)
        cr.translate(*position)

        layout = cr.create_pango_layout
        layout.set_text(text)
        layout.font_description = Pango::FontDescription.new(font)
        layout.set_width((pixbuf.width - position[0] - 100) * Pango::SCALE)
        layout.context_changed
        ink, = layout.pixel_extents
        cr.set_source_rgba(0, 0, 0, 0.3)
        cr.rectangle(-25, -25, ink.width + 50, ink.height + 50)
        cr.fill
        cr.set_source_rgb(1, 1, 1)
        cr.show_pango_layout(layout)
      end

      final_pb = surface.to_pixbuf
      cr.destroy
      surface.destroy
      final_pb
    end
  end

  class ImageBorder < ImageOp
    attr_accessor :style, :colour, :crop, :size, :print_size, :shrink, :border_size

    def initialize(style = 'none', colour = 'white')
      super()
      @style = style
      @colour = colour
    end

    def call(_image, pixbuf)
      return pixbuf unless %w[square retro].include? @style

      surface = Cairo::ImageSurface.new(:rgb24, pixbuf.width, pixbuf.height)
      cr = Cairo::Context.new(surface)

      img_width = pixbuf.width
      img_height = pixbuf.height

      cr.save do
        if @crop && ((@crop[0]).negative? || (@crop[1]).negative?)
          img_width = size[0]
          img_height = size[1]
          cr.translate(- @crop[0], - @crop[1])
        end

        cr.save do
          cr.set_operator :source
          cr.set_source_rgb 1, 1, 1
          cr.paint

          cr.rectangle(0, 0, img_width, img_height)
          case colour
          when 'dominant'
            pixbuf.scale_max(400).save(fn = "/tmp/hist-#{$PROCESS_ID}.#{Time.now.to_i}", 'jpeg')
            hgram = Colorscore::Histogram.new(fn)
            begin
              File.unlink(fn)
            rescue StandardError
              nil
            end
            col = hgram.scores.first[1]
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

      border_scale = [img_width, img_height].max.to_f / print_size.max.to_i
      size = @border_size
      size *= border_scale
      x = size
      y = size

      # This biggest impact will be on the smallest side, so to avoid white
      # edges between photo and border scale by the longest changed side.
      longest_side = [pixbuf.width, pixbuf.height].max.to_f

      # Should be less than 1
      pb_scale = (longest_side - (size * 2)) / longest_side

      if @crop && ((@crop[0]).negative? || (@crop[1]).negative?)
        x -= @crop[0]
        y -= @crop[1]
      end

      case style
      when 'retro'
        # WARNING: CairoUtils class is not available in this gem!
        CairoUtils.rounded_rectangle(cr, x, y,
                                     img_width + x - (size * 2), img_height + y - (size * 2), size)
      when 'square'
        cr.rectangle(x, y, img_width - (size * 2), img_height - (size * 2))
      end
      cr.clip

      if @shrink
        cr.translate(size, size)
        cr.scale(pb_scale, pb_scale)
      end
      cr.set_source_pixbuf(pixbuf)
      cr.rectangle(0, 0, pixbuf.width, pixbuf.height)

      cr.paint(1.0)
      final_pb = surface.to_pixbuf
      cr.destroy
      surface.destroy
      final_pb
    end
  end

  class Gamma < ImageOp
    attr_reader :gamma

    def initialize(gamma = 1.0)
      super()
      @gamma = gamma
    end

    def call(_image, pixbuf)
      if (@gamma - 1.0).abs < Float::EPSILON
        pixbuf
      else
        PixbufUtils.gamma(pixbuf, @gamma)
      end
    end

    def priority
      90
    end
  end

  class Colourify < ImageOp
    attr_reader :op

    def initialize(operation, alpha = 255)
      super()
      @operation = operation
      @alpha = alpha
    end

    def alpha
      @alpha || 255
    end

    def sepia(pixbuf)
      PixbufUtils.tint(pixbuf, 25, 5, -25, alpha)
    end

    def bluetone(pixbuf)
      PixbufUtils.tint(pixbuf, -10, 5, 25, alpha)
    end

    def null(pixbuf)
      pixbuf
    end
    alias full null # WebKiosk
    alias colour null # WebKiosk

    def greyscale(pixbuf)
      PixbufUtils.tint(pixbuf, 0, 0, 0, alpha)
    end
    alias bw greyscale # WebKiosk

    def call(_image, pixbuf)
      if @operation && respond_to?(@operation)
        __send__(@operation, pixbuf)
      else
        pixbuf # Default is nothing
      end
    end
  end
end
