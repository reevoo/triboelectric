# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'triboelectric/version'

Gem::Specification.new do |spec|
  spec.name          = "triboelectric"
  spec.version       = Triboelectric::VERSION
  spec.authors       = ["Ed Robinson"]
  spec.email         = ["ed@reevoo.com"]

  spec.summary       = %q{Manage assets across rolling deploys}
  spec.homepage      = "https://github.com/reevoo/triboelectric"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/**.rb", "README.md", "LICENCE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
