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
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'atk'
  spec.add_dependency 'cairo'
  spec.add_dependency 'colorscore'
  spec.add_dependency 'gdk_pixbuf2', '> 3.4.0'
  spec.add_dependency 'pango'
  spec.add_dependency 'rake-compiler'

  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'super_diff'
end
