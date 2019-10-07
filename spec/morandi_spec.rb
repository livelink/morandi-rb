# frozen_string_literal: true

require 'fileutils'
require 'morandi'

RSpec.describe Morandi, '#process' do
  context 'in command mode' do
    it 'should create ouptut' do
      Morandi.process('sample/sample.jpg', {}, out = 'sample/out_plain.jpg')
      expect(File.exist?(out))
    end

    it 'should do rotation of images' do
      original = Gdk::Pixbuf.get_file_info('sample/sample.jpg')
      Morandi.process('sample/sample.jpg', {
                        'angle' => 90
                      }, out = 'sample/out_rotate90.jpg')
      expect(File.exist?(out))
      _, width, height = Gdk::Pixbuf.get_file_info(out)
      expect(original[1]).to eq(height)
      expect(original[2]).to eq(width)
    end

    it 'should accept pixbufs as an argument' do
      pixbuf = Gdk::Pixbuf.new('sample/sample.jpg')
      pro = Morandi::ImageProcessor.new(pixbuf, {}, {})
      pro.process!
      expect(pixbuf.width).to eq(pro.result.width)
    end

    it 'should do cropping of images' do
      Morandi.process('sample/sample.jpg', {
                        'crop' => [10, 10, 300, 300]
                      }, out = 'sample/out_crop.jpg')
      expect(File.exist?(out))
      _, width, height = Gdk::Pixbuf.get_file_info(out)
      expect(width).to eq(300)
      expect(height).to eq(300)
    end

    it 'should use user supplied path.icc' do
      src = 'sample/sample.jpg'
      icc = '/tmp/this-is-secure-thing.jpg'
      default_icc = Morandi::ImageProcessor.default_icc_path(src)
      out = 'sample/out_icc.jpg'
      FileUtils.rm_f(default_icc)
      Morandi.process(src, {}, out, 'path.icc' => icc)
      expect(File).to exist(icc)
      expect(File).not_to exist(default_icc)
    end

    it 'should ignore user supplied path.icc' do
      src = 'sample/sample.jpg'
      icc = '/tmp/this-is-insecure-thing.jpg'
      default_icc = Morandi::ImageProcessor.default_icc_path(src)
      FileUtils.rm_f(icc)
      FileUtils.rm_f(default_icc)
      out = 'sample/out_icc.jpg'
      Morandi.process(src, { 'path.icc' => icc, 'output.max' => 200 }, out)
      expect(File).not_to exist(icc)
      expect(File).to exist(default_icc)
    end

    it 'should do cropping of images with a string' do
      Morandi.process('sample/sample.jpg', {
                        'crop' => '10,10,300,300'
                      }, out = 'sample/out_crop.jpg')
      expect(File.exist?(out))
      _, width, height = Gdk::Pixbuf.get_file_info(out)
      expect(width).to eq(300)
      expect(height).to eq(300)
    end

    it 'should reduce the size of images' do
      Morandi.process('sample/sample.jpg', {
                        'output.max' => 200
                      }, out = 'sample/out_reduce.jpg')
      expect(File.exist?(out))
      _, width, height = Gdk::Pixbuf.get_file_info(out)
      expect(width).to be <= 200
      expect(height).to be <= 200
    end

    it 'should reduce the straighten images' do
      Morandi.process('sample/sample.jpg', {
                        'straighten' => 5
                      }, out = 'sample/out_straighten.jpg')
      expect(File.exist?(out))
      info, _, _ = Gdk::Pixbuf.get_file_info(out)
      expect(info.name).to eq('jpeg')
    end

    it 'should reduce the gamma correct images' do
      Morandi.process('sample/sample.jpg', {
                        'gamma' => 1.2
                      }, out = 'sample/out_gamma.jpg')
      expect(File.exist?(out))
      info, _, _ = Gdk::Pixbuf.get_file_info(out)
      expect(info.name).to eq('jpeg')
    end

    it 'should reduce the size of images' do
      Morandi.process('sample/sample.jpg', {
                        'fx' => 'sepia'
                      }, out = 'sample/out_sepia.jpg')
      expect(File.exist?(out))
      info, _, _ = Gdk::Pixbuf.get_file_info(out)
      expect(info.name).to eq('jpeg')
    end

    it 'should output at the specified size' do
      Morandi.process('sample/sample.jpg', {
                        'output.width' => 300,
                        'output.height' => 200,
                        'image.auto-crop' => true,
                        'output.limit' => true
                      }, out = 'sample/out_at_size.jpg')
      expect(File.exist?(out))
      info, width, height = Gdk::Pixbuf.get_file_info(out)
      expect(info.name).to eq('jpeg')
      expect(width).to be <= 300
      expect(height).to be <= 200
    end

    it 'should blur the image' do
      Morandi.process('sample/sample.jpg', {
        'sharpen'  => -3
      }, out = 'sample/out_blur.jpg')
      expect(File.exist?(out))
    end

    it 'should apply a border and maintain the target size' do
      Morandi.process('sample/sample.jpg', {
        'border-style'     => 'square',
        'background-style' => 'dominant',
        'border-size-mm'   => 5,
        'output.width'     => 800,
        'output.height'    => 650
      }, out = 'sample/out_border.jpg')
      expect(File.exist?(out))

      info, width, height = Gdk::Pixbuf.get_file_info(out)
      expect(info.name).to eq('jpeg')
      expect(width).to eq 800
      expect(height).to eq 650
    end

    it 'should apply multiple transformations' do
      Morandi.process('sample/sample.jpg', {
        'brighten'         => 5,
        'contrast'         => 5,
        'sharpen'          => 2,
        'fx'               => 'greyscale',
        'border-style'     => 'solid',
        'background-style' => '#00FF00',
        'crop'             => [50, 0, 750, 650],
        'output.width'     => 300,
        'output.height'    => 260,
        'output.limit'     => true
      }, out = 'sample/out_various.jpg')
      expect(File.exist?(out))

      info, width, height = Gdk::Pixbuf.get_file_info(out)
      expect(info.name).to eq('jpeg')
      expect(width).to eq 300
      expect(height).to eq 260
    end
  end

  context 'with increasing quality settings' do
    let(:max_quality_file_size) do
      Morandi.process('sample/sample.jpg', { 'quality' => 100 }, 'sample/out-100.jpg')
      File.size('sample/out-100.jpg')
    end

    let(:default_of_97_quality) do
      Morandi.process('sample/sample.jpg', {}, 'sample/out-97.jpg')
      File.size('sample/out-97.jpg')
    end

    let(:quality_of_40_by_options_args) do
      Morandi.process('sample/sample.jpg', { 'quality' => 40 }, 'sample/out-40.jpg')
      File.size('sample/out-40.jpg')
    end

    # Sort the output files' sizes and expect them to match to quality order
    it 'creates files of increasing size' do
      created_file_sizes = [default_of_97_quality, max_quality_file_size, quality_of_40_by_options_args].sort
      expect(created_file_sizes).to eq([quality_of_40_by_options_args, default_of_97_quality, max_quality_file_size])
    end
  end
end
