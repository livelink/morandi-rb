require 'gdk_pixbuf2'

class Morandi::ProfiledPixbuf < GdkPixbuf::Pixbuf
  def valid_jpeg?(filename)
    return false unless File.exist?(filename)
    return false unless File.size(filename) > 0

    type, = GdkPixbuf::Pixbuf.get_file_info(filename)

    type && type.name.eql?('jpeg')
  rescue
    false
  end

  def self.default_icc_path(path)
    "#{path}.icc.jpg"
  end

  def initialize(options, local_options = {})
    @local_options = local_options || {}

    if options[:file]
      @file = options[:file]

      if suitable_for_jpegicc?
        icc_file = icc_cache_path

        options[:file] = icc_file if valid_jpeg?(icc_file) || system('jpgicc', '-q97', @file, icc_file)
      end
    end

    super(options)
  end

  protected

  def suitable_for_jpegicc?
    type, = GdkPixbuf::Pixbuf.get_file_info(@file)

    type && type.name.eql?('jpeg')
  end

  def icc_cache_path
    @local_options['path.icc'] || Morandi::ProfiledPixbuf.default_icc_path(@file)
  end
end
