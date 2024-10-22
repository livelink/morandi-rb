# frozen_string_literal: true

require 'gdk_pixbuf2'

module Morandi
  # Converts the file under `path` to sRGB colour space
  class SrgbConversion
    # Performs a conversion to srgb colour space if possible
    # Returns a path to converted file on success or nil on failure
    def self.perform(path, target_path: nil)
      return unless suitable_for_jpegicc?(path)

      icc_file_path = target_path || default_icc_path(path)
      return icc_file_path if valid_jpeg?(icc_file_path)

      system('jpgicc', '-q97', path, icc_file_path, out: '/dev/null', err: '/dev/null')

      return unless valid_jpeg?(icc_file_path)

      icc_file_path
    end

    def self.default_icc_path(path)
      "#{path}.icc.jpg"
    end

    def self.valid_jpeg?(path)
      return false unless File.exist?(path)
      return false unless File.size(path).positive?

      type, = GdkPixbuf::Pixbuf.get_file_info(path)

      type && type.name.eql?('jpeg')
    rescue StandardError
      false
    end

    def self.suitable_for_jpegicc?(path)
      valid_jpeg?(path)
    end
  end
end
