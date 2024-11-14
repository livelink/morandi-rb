# frozen_string_literal: true

require 'open3'

# For testing that under a given path resides an image with desired colourspace.
# The colourspace is currently extracted using imagemagick's `identify`, resulting in values like 'gray' or 'srgb'
# According to docs (https://www.imagemagick.org/script/escape.php), it may include number of channels and meta channels
RSpec::Matchers.define :match_colourspace do |expected_colourspace|
  match do |tested_path|
    raise(ArgumentError, "path #{tested_path} is not a file") unless File.file?(tested_path)

    @colourspace, status = Open3.capture2('identify', '-format', '%[channels]', tested_path)
    raise "Failed to read colorspace of #{tested_path}" unless status.success?

    @colourspace == expected_colourspace
  end

  failure_message do
    "Colourspaces don't match. Expected: #{expected_colourspace}, got: #{@colourspace}"
  end
end
