# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'atruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'atruby'
  spec.version       = Atruby::VERSION
  spec.authors       = ['bsmth']
  spec.email         = ['brian.smith@emnify.com']

  spec.summary       = 'Ruby AT Commands.'
  # spec.description   = %q{TODO: Write a longer description or delete this line.}

  spec.homepage      = 'https://github.com/bsmth/atruby'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'test-unit'
  spec.add_dependency 'rpi_gpio'
  spec.add_dependency 'rubyserial'
end