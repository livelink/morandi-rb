require 'gdk_pixbuf2'

class Morandi::ProfiledPixbuf < Gdk::Pixbuf
  def valid_jpeg?(filename)
    return false unless File.exist?(filename)
    return false unless File.size(filename) > 0

    type, _, _ = Gdk::Pixbuf.get_file_info(filename)

    type && type.name.eql?('jpeg')
  rescue
    false
  end

  def self.default_icc_path(path)
    "#{path}.icc.jpg"
  end

  def initialize(*args)
    @local_options = args.last.is_a?(Hash) && args.pop || {}

    if args[0].is_a?(String)
      @file = args[0]

      if suitable_for_jpegicc?
        icc_file = icc_cache_path

        args[0] = icc_file if valid_jpeg?(icc_file) || system("jpgicc", "-q97", @file, icc_file)
      end
    end

    super(*args)
  rescue Gdk::PixbufError::CorruptImage => e
    if args[0].is_a? String
      temp_path =  Tempfile.new.path
      pixbuf.save(temp_path, 'jpeg')
      args[0] = temp_path
      super(*args)
    else
      throw e
    end
  end


  protected
  def suitable_for_jpegicc?
    type, _, _ = Gdk::Pixbuf.get_file_info(@file)

    type && type.name.eql?('jpeg')
  end

  def icc_cache_path
    @local_options['path.icc'] || Morandi::ProfiledPixbuf.default_icc_path(@file)
  end
end
