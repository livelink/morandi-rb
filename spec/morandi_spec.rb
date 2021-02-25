# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe Morandi, '#process' do
  subject(:process_image) do
    Morandi.process(file_arg, options, file_out)
  end

  let(:file_in) { 'sample/sample.jpg' }
  let(:file_out) { 'sample/sample_out.jpg' }
  let(:file_arg) { file_in }
  let(:options) { {} }
  let(:original_image_width) { 800 }
  let(:original_image_height) { 650 }
  let(:processed_image_info) { GdkPixbuf::Pixbuf.get_file_info(file_out) }
  let(:processed_image_type) { processed_image_info[0].name }
  let(:processed_image_width) { processed_image_info[1] }
  let(:processed_image_height) { processed_image_info[2] }

  before(:all) do
    FileUtils.mkdir_p('sample')
  end

  before do
    generate_test_image(file_in, original_image_width, original_image_height) unless File.exist?(file_in)
  end

  after do
    FileUtils.rm_rf(Dir['sample/*'])
  end

  after(:all) do
    FileUtils.remove_dir('sample/')
  end

  context 'in command mode' do
    describe 'when given an input without any options' do
      it 'should create ouptut' do
        process_image
        expect(File).to exist(file_out)
      end
    end

    describe 'when given an input without any options' do
      let(:file_arg) { Morandi::ProfiledPixbuf.from_string(File.read(file_in)) }
      it 'should create ouptut' do
        process_image
        expect(File).to exist(file_out)
      end
    end

    describe 'with a big image and a bigger cropped area to fill' do
      let(:options) do
        {
          'crop' => '0,477,15839,18804',
          'angle' => 90,
          'fx' => 'colour',
          'straighten' => 0.0,
          'gamma' => 0.98,
          'redeye' => []
        }
      end

      it 'should create ouptut' do
        process_image
        expect(File).to exist(file_out)
      end
    end

    describe 'when given an angle of rotation' do
      let(:options) { { 'angle' => 90 } }

      it 'should do rotation of images' do
        process_image

        expect(File).to exist(file_out)
        expect(original_image_width).to eq(processed_image_height)
        expect(original_image_height).to eq(processed_image_width)
      end
    end

    describe 'when given a pixbuf as an input' do
      subject(:process_image) do
        Morandi.process(pixbuf, options, file_out)
      end

      let(:pixbuf) { GdkPixbuf::Pixbuf.new(file: file_in) }

      it 'should process the file' do
        process_image

        expect(processed_image_width).to eq(pixbuf.width)
        expect(processed_image_height).to eq(pixbuf.height)
      end
    end

    context 'when give a "crop" option' do
      let(:cropped_width) { 300 }
      let(:cropped_height) { 300 }

      describe 'when given an array of dimensions' do
        let(:options) { { 'crop' => [10, 10, cropped_width, cropped_height] } }

        it 'should crop the image' do
          process_image

          expect(File).to exist(file_out)
          expect(processed_image_width).to eq(cropped_width)
          expect(processed_image_height).to eq(cropped_height)
        end
      end

      describe 'when given a string of dimensions' do
        let(:options) { { 'crop' => "10,10,#{cropped_width},#{cropped_height}" } }

        it 'should do cropping of images with a string' do
          process_image

          expect(File).to exist(file_out)
          expect(processed_image_width).to eq(cropped_width)
          expect(processed_image_height).to eq(cropped_height)
        end
      end
    end

    describe 'when the user supplies a path.icc in the "local_options" argument' do
      subject(:process_image) do
        Morandi.process(file_in, options, file_out, local_options)
      end

      let(:icc_path) { 'sample/icc_secure_test.jpg' }
      let(:local_options) { { 'path.icc' => icc_path } }
      let(:icc_width) { 900 }
      let(:icc_height) { 400 }

      before do
        generate_test_image(icc_path, icc_width, icc_height)
      end

      it 'it should use a file at this location as the input' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_width).to eq(icc_width)
        expect(processed_image_height).to eq(icc_height)
      end

      context 'if no file at this location exists' do
        let(:different_icc_path) { 'sample/different_secure_test.jpg' }
        let(:local_options) { { 'path.icc' => different_icc_path } }

        it 'should create one' do
          process_image

          expect(File).to exist(different_icc_path)
        end
      end
    end

    describe 'when the user supplies a path.icc in the "options" argument' do
      let(:icc_path) { 'sample/icc_insecure_test.jpg' }
      let(:options) { { 'path.icc' => icc_path } }
      let(:icc_width) { 900 }
      let(:icc_height) { 400 }

      before do
        generate_test_image(icc_path, icc_width, icc_height)
      end

      it 'should ignore the file at this path' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_width).not_to eq(icc_width)
        expect(processed_image_height).not_to eq(icc_height)
      end
    end

    describe 'when given an output.max option' do
      let(:options) { { 'output.max' => max_size } }
      let(:max_size) { 200 }

      it 'should reduce the size of images' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_width).to be <= (max_size)
        expect(processed_image_height).to be <= (max_size)
      end
    end

    describe 'when given a straighten option' do
      let(:options) { { 'straighten' => 5 } }

      it 'should reduce the straighten images' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_type).to eq('jpeg')
      end
    end

    describe 'when given a gamma option' do
      let(:options) { { 'gamma' => 1.2 } }

      it 'should reduce the straighten images' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_type).to eq('jpeg')
      end
    end

    describe 'when given an fx option' do
      let(:options) { { 'fx' => 'sepia' } }

      it 'should reduce the size of images' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_type).to eq('jpeg')
      end
    end

    describe 'when changing the dimensions and auto-cropping' do
      let(:max_width) { 300 }
      let(:max_height) { 200 }

      let(:options) do
        {
          'output.width' => max_width,
          'output.height' => max_height,
          'image.auto-crop' => true,
          'output.limit' => true
        }
      end

      it 'should output at the specified size, or less' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_type).to eq('jpeg')
        expect(processed_image_width).to be <= max_width
        expect(processed_image_height).to be <= max_height
      end
    end

    describe 'when given a redeye option' do
      let(:file_in) { 'spec/fixtures/public-domain-redeye-image-from-wikipedia.jpg' }
      let(:options) { { 'redeye' => [[540, 650]] } }

      it 'should blur the image' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_type).to eq('jpeg')

        expect(crude_average_colour(GdkPixbuf::Pixbuf.new(file: file_in).subpixbuf(505, 605, 100,
                                                                                   100))).to eq([116, 28, 43])
        expect(crude_average_colour(GdkPixbuf::Pixbuf.new(file: file_out).subpixbuf(505, 605, 100,
                                                                                    100))).to eq([30, 36, 37])
      end
    end

    describe 'when given a sharpen option' do
      let(:options) { { 'sharpen' => -3 } }

      it 'should blur the image' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_type).to eq('jpeg')
      end
    end

    describe 'when given a postive sharpen option' do
      let(:options) { { 'sharpen' => 3 } }

      it 'should sharpen the image' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_type).to eq('jpeg')
      end
    end

    describe 'when applying a border and maintaining the original size' do
      let(:options) do
        {
          'border-style' => 'square',
          'background-style' => background_style,
          'border-size-mm' => 5,
          'output.width' => original_image_width,
          'output.height' => original_image_height
        }
      end

      context 'dominant colour background' do
        let(:background_style) { 'dominant' }

        it 'should maintain the target size' do
          process_image

          expect(File).to exist(file_out)
          expect(processed_image_type).to eq('jpeg')
          expect(processed_image_width).to eq(original_image_width)
          expect(processed_image_height).to eq(original_image_height)
        end
      end

      context 'black colour background' do
        let(:background_style) { 'black' }

        it 'should maintain the target size' do
          process_image

          expect(File).to exist(file_out)
          expect(processed_image_type).to eq('jpeg')
          expect(processed_image_width).to eq(original_image_width)
          expect(processed_image_height).to eq(original_image_height)
        end
      end

      context 'white colour background' do
        let(:background_style) { 'white' }

        it 'should maintain the target size' do
          process_image

          expect(File).to exist(file_out)
          expect(processed_image_type).to eq('jpeg')
          expect(processed_image_width).to eq(original_image_width)
          expect(processed_image_height).to eq(original_image_height)
        end
      end

      context 'retro colour background' do
        let(:background_style) { 'retro' }

        it 'should maintain the target size' do
          process_image

          expect(File).to exist(file_out)
          expect(processed_image_type).to eq('jpeg')
          expect(processed_image_width).to eq(original_image_width)
          expect(processed_image_height).to eq(original_image_height)
        end
      end
    end

    describe 'when applying a retro border and maintaining the original size' do
      let(:options) do
        {
          'border-style' => 'retro',
          'background-style' => 'dominant',
          'border-size-mm' => 5,
          'output.width' => original_image_width,
          'output.height' => original_image_height
        }
      end

      it 'should maintain the target size' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_type).to eq('jpeg')
        expect(processed_image_width).to eq(original_image_width)
        expect(processed_image_height).to eq(original_image_height)
      end
    end

    describe 'when applying multiple transformations' do
      let(:desired_image_width) { 300 }
      let(:desired_image_height) { 260 }

      let(:options) do
        {
          'brighten' => 5,
          'contrast' => 5,
          'sharpen' => 2,
          'fx' => 'greyscale',
          'border-style' => 'solid',
          'background-style' => '#00FF00',
          'crop' => [50, 0, 750, 650],
          'output.width' => desired_image_width,
          'output.height' => desired_image_height,
          'output.limit' => true
        }
      end

      it 'should shrink the image to the desired dimensions' do
        process_image

        expect(File).to exist(file_out)
        expect(processed_image_type).to eq('jpeg')
        expect(processed_image_width).to eq(desired_image_width)
        expect(processed_image_height).to eq(desired_image_height)
      end
    end
  end

  context 'with increasing quality settings' do
    let!(:max_quality_file) do
      Morandi.process(file_in, { 'quality' => 100 }, 'sample/out-100.jpg')
    end

    let(:max_quality_file_size) { File.size('sample/out-100.jpg') }

    let!(:default_of_97_quality_file) do
      Morandi.process(file_in, {}, 'sample/out-97.jpg')
    end

    let(:default_of_97_quality_file_size) { File.size('sample/out-97.jpg') }

    let!(:quality_of_40_file) do
      Morandi.process(file_in, { 'quality' => 40 }, 'sample/out-40.jpg')
    end

    let(:quality_of_40_file_size) { File.size('sample/out-40.jpg') }

    let(:created_file_sizes) do
      [default_of_97_quality_file_size, max_quality_file_size, quality_of_40_file_size]
    end

    let(:files_in_increasing_quality_order) do
      [quality_of_40_file_size, default_of_97_quality_file_size, max_quality_file_size]
    end

    it 'creates files of increasing size' do
      expect(created_file_sizes.sort).to eq(files_in_increasing_quality_order)
    end
  end

  def generate_test_image(at_file_path, width = 600, height = 300)
    system(
      'convert',
      '-size',
      "#{width}x#{height}",
      '-seed',
      '5432',
      'plasma:red-blue',
      at_file_path
    )
  end

  def crude_average_colour(pixbuf)
    get_pixels = lambda do |pb|
      pb.pixels.each_slice(pb.rowstride).map do |row|
        row.each_slice(3).to_a[0...pb.width]
      end.to_a[0...pb.height].flatten(1)
    end
    avg_color = lambda do |pixels|
      list = pixels.inject([0, 0, 0]) do |(br, bg, bb), (r, g, b)|
        [br + r, bg + g, bb + b]
      end
      list.map { |a| (a / pixels.size.to_f).to_i }
    end
    avg_color.call(get_pixels.call(pixbuf))
  end
end
