# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe GdkPixbufCairo do
  context '#surface_to_pixbuf' do
    it 'should convert an alpha channel pixbuf to a Cairo::ImageSurface and back again un-pre-multiply the alpha' do
      pb = GdkPixbuf::Pixbuf.new(colorspace: GdkPixbuf::Colorspace::RGB,
                                 has_alpha: true,
                                 bits_per_sample: 8,
                                 width: 4,
                                 height: 4)
      pb.fill!(0xffffff7f)
      surface = pb.to_cairo_image_surface
      expect(surface.data.unpack('C*')).to eq([127, 127, 127, 127] * (4**2))

      pixbuf = surface.to_gdk_pixbuf
      expect(pixbuf).not_to eq pb
      expect(pixbuf.pixels).to eq([255, 255, 255, 127] * (4**2))
    end

    it 'should convert an channel pixbuf to a Cairo::ImageSurface and back again un-pre-multiply the alpha' do
      pb = GdkPixbuf::Pixbuf.new(colorspace: GdkPixbuf::Colorspace::RGB,
                                 has_alpha: false,
                                 bits_per_sample: 8,
                                 width: 4,
                                 height: 4)
      pb.fill!(0xffffff00)
      surface = pb.to_cairo_image_surface
      # cairo is word aligned, even if the alpha channel isn't used
      expect(surface.data.unpack('C*')).to eq([255, 255, 255, 255] * (4**2))

      pixbuf = surface.to_gdk_pixbuf
      expect(pixbuf).not_to eq pb
      expect(pixbuf.n_channels).to eq 3
      expect(pixbuf.pixels).to eq([255, 255, 255] * (4**2))
    end
  end
end
