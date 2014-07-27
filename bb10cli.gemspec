# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bb10cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'bb10cli'
  spec.version       = Bb10Cli::VERSION
  spec.authors       = ['Alex Zepeda']
  spec.email         = ['alex@inferiorhumanorgans.com']
  spec.description   = 'Blackberry 10 CLI tool'
  spec.summary       = "bb10cli-#{spec.version}"
  spec.homepage      = ''
  spec.license       = 'BSD'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  %w(httparty httparty_with_cookies multipart-post thor pager).each do |dependency|
    spec.add_dependency(dependency)
  end

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
