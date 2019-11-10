# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'fluent-plugin-sforce'
  spec.version       = File.read('VERSION').strip
  spec.authors       = ['Makoto Tajitsu']
  spec.email         = ['makoto_tajitsu@hotmail.co.jp']
  spec.summary       = %q{Fluent Plugin to export data from Salesforce.com.}
  spec.description   = %q{Fluent Plugin to export data from Salesforce.com.}
  spec.homepage      = 'https://github.com/tzmfreedom/fluent-plugin-sforce'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'fluentd'
  spec.add_dependency 'restforce', '~> 3.0.0'
  spec.add_dependency 'faye', '~> 1.2.4'
  spec.add_dependency 'nokogiri', '>= 1.10.4'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'test-unit'
end
