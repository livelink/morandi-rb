# frozen_string_literal: true

require 'gdk_pixbuf2'

class Morandi::ProfiledPixbuf < Gdk::Pixbuf
  def valid_jpeg?(filename)
    return false unless File.exist?(filename)
    return false unless File.size(filename) > 0

    type, _, _ = GdkPixbuf::Pixbuf.get_file_info(filename)

    type && type.name.eql?('jpeg')
  rescue
    false
  end

  def self.from_string(string, loader: nil, chunk_size: 4096)
    loader ||= Gdk::PixbufLoader.new
    ((string.bytesize + chunk_size - 1) / chunk_size).times do |i|
      loader.write(string.byteslice(i * chunk_size, chunk_size))
    end
    loader.close
    loader.pixbuf
  end

  def self.default_icc_path(path)
    "#{path}.icc.jpg"
  end

  def initialize(*args, local_options)
    @local_options = local_options

    if args[0].is_a?(String)

      @file = args[0]

      if suitable_for_jpegicc?
        icc_file = icc_cache_path

        args[0] = icc_file if (valid_jpeg?(icc_file) || system("jpgicc", "-q97", @file, icc_file))
      end
    end

    super(*args)
  rescue Gdk::PixbufError::CorruptImage => e
    if args[0].is_a?(String) && defined? Tempfile
      temp =  Tempfile.new
      pixbuf = self.class.from_string(File.read(args[0]))
      pixbuf.save(temp.path, 'jpeg')
      args[0] = temp.path
      super(*args)
      temp.close
      temp.unlink
    else
      throw e
    end
  end


  protected
  def suitable_for_jpegicc?
    type, _, _ = GdkPixbuf::Pixbuf.get_file_info(@file)

    type && type.name.eql?('jpeg')
  end

  def icc_cache_path
    @local_options['path.icc'] || Morandi::ProfiledPixbuf.default_icc_path(@file)
  end
end
