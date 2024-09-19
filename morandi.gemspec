# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'morandi/version'

Gem::Specification.new do |spec|
  spec.name          = 'morandi'
  spec.version       = Morandi::VERSION
  spec.authors       = ["Geoff Youngs\n\n\n"]
  spec.email         = ['git@intersect-uk.co.uk']
  spec.summary       = 'Simple Image Edits'
  spec.description   = 'Apply simple edits to images'
  spec.homepage      = 'https://github.com/livelink/morandi-rb'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.0'
  spec.files         = Dir['CHANGELOG.md', 'LICENSE.txt', 'README.md', 'ext/**/*', 'lib/**/*']
  spec.require_paths = ['lib']

  spec.extensions    = %w[ext/morandi_native/extconf.rb ext/gdk_pixbuf_cairo/extconf.rb]

  spec.metadata['source_code_uri'] = 'https://github.com/livelink/morandi-rb'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'atk', '~> 4.0'
  spec.add_dependency 'cairo', '~> 1.0'
  spec.add_dependency 'colorscore', '~> 0.0'
  spec.add_dependency 'gdk_pixbuf2', '~> 4.0'
  spec.add_dependency 'pango', '~> 4.0'
  spec.add_dependency 'rake-compiler', '~> 1.2'
end
