# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','charging','version.rb'])

Gem::Specification.new do |spec|
  spec.name          = "charging-client"
  spec.version       = Charging::VERSION
  spec.authors       = ["Rodrigo Tassinari de Oliveira", "Celestino Gomes"]
  spec.email         = ["rodrigo@pittlandia.net", "rodrigo.tassinari@myfreecomm.com.br", "tinorj@gmail.com", "celestino.gomes@myfreecomm.com.br"]
  spec.description   = %q{A Ruby client for the Charging REST API}
  spec.summary       = %q{A Ruby client for the Charging REST API}
  spec.homepage      = "https://github.com/myfreecomm/charging-client-ruby"
  spec.license       = "Apache-v2"
  spec.has_rdoc      = true

  # VCR cassettes are too long for the gemspec, see http://stackoverflow.com/questions/14371686/building-rails-3-engine-throwing-gempackagetoolongfilename-error
  # spec.files         = `git ls-files`.split($/)
  spec.files         = `git ls-files`.split($/).reject { |f| f =~ %r{(vcr_cassettes)/} }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client", "~> 1.6.7"
  spec.add_dependency "multi_json", "~> 1.11"

  spec.add_development_dependency "bundler", "> 1.3.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rdoc', '~> 4.0'
  spec.add_development_dependency "rspec", "~> 2.13"
  spec.add_development_dependency "vcr", "~> 2.4"
  spec.add_development_dependency "webmock", "~> 1.9.3"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "pry-nav", "~> 0.2"
  spec.add_development_dependency "awesome_print", "~> 1.1"
  spec.add_development_dependency "simplecov", "~> 0.7"
  spec.add_development_dependency "coveralls", "~> 0.6"
end
