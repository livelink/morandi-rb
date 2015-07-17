require 'morandi'

RSpec.describe Morandi, "#process_to_file" do
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

    it "should do cropping of images" do
      Morandi.process("sample/sample.jpg", {
        'crop' => [10,10,300,300]
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
end
