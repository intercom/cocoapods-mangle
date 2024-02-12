# coding: utf-8
require File.expand_path('../lib/cocoapods_mangle/gem_version', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = CocoapodsMangle::NAME
  spec.version     = CocoapodsMangle::VERSION
  spec.license     = 'Apache-2.0'
  spec.email       = ['james@intercom.io']
  spec.homepage    = 'https://github.com/intercom/cocoapods-mangle'
  spec.authors     = ['James Treanor, Brian Boyle']
  spec.summary     = 'A CocoaPods plugin which mangles ' \
                     'the symbols of your dependencies'
  spec.description = 'Mangling your dependencies symbols allows more than '    \
                     'one copy of a dependency to exist without errors. This ' \
                     'plugin mangles your dependecies to make this possible'
  spec.files            = Dir['lib/**/*.rb']
  spec.test_files       = Dir['spec/**/*.rb']
  spec.extra_rdoc_files = ['README.md', 'CHANGELOG.md']
  spec.require_paths    = ['lib']
  spec.add_dependency 'cocoapods', '~> 1.15'
end
