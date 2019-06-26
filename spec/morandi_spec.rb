require 'morandi'

RSpec.describe Morandi, "#process" do
  context "in command mode" do
    it "should create ouptut" do
      Morandi.process("sample/sample.jpg", {}, out="sample/out_plain.jpg")
      expect(File.exist?(out))
    end

    it "should do rotation of images" do
      original = Gdk::Pixbuf.get_file_info("sample/sample.jpg")
      Morandi.process("sample/sample.jpg", {
        'angle' => 90
      }, out="sample/out_rotate90.jpg")
      expect(File.exist?(out))
      _,w,h = Gdk::Pixbuf.get_file_info(out)
      expect(original[1]).to eq(h)
      expect(original[2]).to eq(w)
    end

    it "should accept pixbufs as an argument" do
      pixbuf = Gdk::Pixbuf.new("sample/sample.jpg")
      pro = Morandi::ImageProcessor.new(pixbuf, {}, {})
      pro.process!
      expect(pixbuf.width).to eq(pro.result.width)
    end

    it "should do cropping of images" do
      Morandi.process("sample/sample.jpg", {
        'crop' => [10,10,300,300]
      }, out="sample/out_crop.jpg")
      expect(File.exist?(out))
      _,w,h = Gdk::Pixbuf.get_file_info(out)
      expect(w).to eq(300)
      expect(h).to eq(300)
    end

    it "should use user supplied path.icc" do
      src = 'sample/sample.jpg'
      icc = '/tmp/this-is-secure-thing.jpg'
      default_icc = Morandi::ImageProcessor.default_icc_path(src)
      out = 'sample/out_icc.jpg'
      File.unlink(default_icc) rescue nil
      Morandi.process(src, { }, out, { 'path.icc' => icc })
      expect(File).to exist(icc)
      expect(File).not_to exist(default_icc)
    end

    it "should ignore user supplied path.icc" do
      src = 'sample/sample.jpg'
      icc = '/tmp/this-is-insecure-thing.jpg'
      default_icc = Morandi::ImageProcessor.default_icc_path(src)
      File.unlink(icc) rescue 0
      File.unlink(default_icc) rescue 0
      out = 'sample/out_icc.jpg'
      Morandi.process(src, { 'path.icc' => icc, 'output.max' => 200 }, out)
      expect(File).not_to exist(icc)
      expect(File).to exist(default_icc)
    end

    it "should do cropping of images with a string" do
      Morandi.process("sample/sample.jpg", {
        'crop' => "10,10,300,300"
      }, out="sample/out_crop.jpg")
      expect(File.exist?(out))
      _,w,h = Gdk::Pixbuf.get_file_info(out)
      expect(w).to eq(300)
      expect(h).to eq(300)
    end

    it "should reduce the size of images" do
      Morandi.process("sample/sample.jpg", {
        'output.max' => 200
      }, out="sample/out_reduce.jpg")
      expect(File.exist?(out))
      _,w,h = Gdk::Pixbuf.get_file_info(out)
      expect(w).to be <= 200
      expect(h).to be <= 200
    end

    it "should reduce the straighten images" do
      Morandi.process("sample/sample.jpg", {
        'straighten' => 5
      }, out="sample/out_straighten.jpg")
      expect(File.exist?(out))
      _,w,h = Gdk::Pixbuf.get_file_info(out)
      expect(_.name).to eq('jpeg')
    end

    it "should reduce the gamma correct images" do
      Morandi.process("sample/sample.jpg", {
        'gamma' => 1.2
      }, out="sample/out_gamma.jpg")
      expect(File.exist?(out))
      _,w,h = Gdk::Pixbuf.get_file_info(out)
      expect(_.name).to eq('jpeg')
    end

    it "should reduce the size of images" do
      Morandi.process("sample/sample.jpg", {
        'fx' => 'sepia'
      }, out="sample/out_sepia.jpg")
      expect(File.exist?(out))
      _,w,h = Gdk::Pixbuf.get_file_info(out)
      expect(_.name).to eq('jpeg')
    end

    it "should output at the specified size" do
      Morandi.process("sample/sample.jpg", {
        'output.width' => 300,
        'output.height' => 200,
        'image.auto-crop' => true,
        'output.limit' => true
      }, out="sample/out_at_size.jpg")
      expect(File.exist?(out))
      _,w,h = Gdk::Pixbuf.get_file_info(out)
      expect(_.name).to eq('jpeg')
      expect(h).to be <= 200
      expect(w).to be <= 300
    end
  end

  context 'with increasing quality settings' do
    let(:max_quality_file_size) do
      Morandi.process("sample/sample.jpg", { 'quality' => 100 }, "sample/out-100.jpg")
      File.size("sample/out-100.jpg")
    end

    let(:default_of_97_quality) do
      Morandi.process("sample/sample.jpg", {}, "sample/out-97.jpg")
      File.size("sample/out-97.jpg")
    end

    let(:quality_of_40_by_options_args) do
      Morandi.process("sample/sample.jpg", { 'quality' => 40 }, "sample/out-40.jpg")
      File.size("sample/out-40.jpg")
    end

    # Sort the output files' sizes and expect them to match to quality order
    it "creates files of increasing size" do
      created_file_sizes = [default_of_97_quality, max_quality_file_size, quality_of_40_by_options_args].sort
      expect(created_file_sizes).to eq([quality_of_40_by_options_args, default_of_97_quality, max_quality_file_size])
    end
  end
end
