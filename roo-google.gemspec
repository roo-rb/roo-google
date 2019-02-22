# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'roo/google/version'

Gem::Specification.new do |spec|
  spec.name          = "roo-google"
  spec.version       = Roo::GOOGLE_VERSION
  spec.authors       = ["Thomas Preymesser", "Hugh McGowan", "Ben Woosley", "Oleksandr Simonov"]
  spec.email         = ["ruby.ruby.ruby.roo@gmail.com", "oleksandr@simonov.me"]
  spec.summary       = "Roo::Google extend Roo to support google spreadsheet files."
  spec.description   = "Roo::Google extend Roo to support google spreadsheet files."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "roo", ">= 2.0", "< 3"
  spec.add_dependency "google_drive", '~> 2'

  spec.add_development_dependency "rake", "~> 10.0"
end
