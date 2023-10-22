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
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.0'
  spec.files         = Dir['CHANGELOG.md', 'LICENSE.txt', 'README.md', 'ext/**/*', 'lib/**/*']
  spec.require_paths = ['lib']

  spec.extensions    = %w[ext/morandi_native/extconf.rb ext/gdk_pixbuf_cairo/extconf.rb]

  spec.add_dependency 'atk', '> 4.0.0'
  spec.add_dependency 'cairo'
  spec.add_dependency 'colorscore'
  spec.add_dependency 'gdk_pixbuf2', '> 4.0.0'
  spec.add_dependency 'pango', '> 4.0.0'
  spec.add_dependency 'rake-compiler'

  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'super_diff'
end
