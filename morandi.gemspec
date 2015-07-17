# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'morandi/version'

Gem::Specification.new do |spec|
  spec.name          = "morandi"
  spec.version       = Morandi::VERSION
  spec.authors       = ["Geoff Youngs\n\n\n"]
  spec.email         = ["git@intersect-uk.co.uk"]
  spec.summary       = %q{Simple Image Edits}
  spec.description   = %q{Apply simple edits to images}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "gdk_pixbuf2"
  spec.add_dependency "cairo"
  spec.add_dependency "pixbufutils"
  spec.add_dependency "redeye"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
