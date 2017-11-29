# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ass_devel/version'

Gem::Specification.new do |spec|
  spec.name          = "ass_devel"
  spec.version       = AssDevel::VERSION
  spec.authors       = ["Leonid Vlasov"]
  spec.email         = ["leoniv.vlasov@gmail.com"]

  spec.summary       = %q{Utilities for developers on 1C:Enterprise platform}
  spec.description   = %q{Provides tools and defines rules for development 1C:Enterprise applications}
  spec.homepage      = "https://github.com/leoniv/ass_devel"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ass_tests"
  spec.add_dependency "ass_ole-snippets-shared", "~> 0.2"
  spec.add_dependency "uuid", "~> 2.3.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "simplecov"
end
