# frozen_string_literal: true

require 'gdk_pixbuf2'

module Morandi
  class ProfiledPixbuf < GdkPixbuf::Pixbuf
    def valid_jpeg?(filename)
      return false unless File.exist?(filename)
      return false unless File.size(filename).positive?

      type, = GdkPixbuf::Pixbuf.get_file_info(filename)

      type && type.name.eql?('jpeg')
    rescue StandardError
      false
    end

    def self.from_string(string, loader: nil, chunk_size: 4096)
      loader ||= GdkPixbuf::PixbufLoader.new
      ((string.bytesize + chunk_size - 1) / chunk_size).times do |i|
        loader.write(string.byteslice(i * chunk_size, chunk_size))
      end
      loader.close
      loader.pixbuf
    end

    def self.default_icc_path(path)
      "#{path}.icc.jpg"
    end

    def initialize(file, local_options, scale_to = nil)
      @local_options = local_options

      if file.is_a?(String)

        @file = file

        if suitable_for_jpegicc?
          icc_file = icc_cache_path

          file = icc_file if valid_jpeg?(icc_file) || system('jpgicc', '-q97', @file, icc_file)
        end
      end

      if scale_to
        super(path: file, width: scale_to, height: scale_to)
      else
        super(file: file)
      end
    rescue Gdk::PixbufError::CorruptImage => e
      if file.is_a?(String) && defined? Tempfile
        temp = Tempfile.new
        pixbuf = self.class.from_string(File.read(file))
        pixbuf.save(temp.path, 'jpeg')
        file = temp.path

        if scale_to
          super(path: file, width: scale_to, height: scale_to)
        else
          super(file: file)
        end

        temp.close
        temp.unlink
      else
        throw e
      end
    end

    protected

    def suitable_for_jpegicc?
      file_type && file_type.name.eql?('jpeg')
    end

    def icc_cache_path
      @local_options['path.icc'] || Morandi::ProfiledPixbuf.default_icc_path(@file)
    end

    private

    def file_type
      GdkPixbuf::Pixbuf.get_file_info(@file)[0]
    end
  end
end
