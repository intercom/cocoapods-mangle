# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods_mangle/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name = CocoapodsMangle::NAME
  spec.version = CocoapodsMangle::VERSION
  spec.description = 'A CocoaPods plugin which mangles the symbols of your dependencies'
  spec.summary = 'Mangling your dependencies symbols allows more than one copy of a dependency to exist without errors. This plugin mangles your dependecies to make this possible'
  spec.authors = ['James Treanor']
  spec.email = ['james@intercom.io']
  spec.files = [
    'lib/cocoapods_plugin.rb',
    'cocoapods-mangle.gemspec'
  ]
  spec.extra_rdoc_files = ['README.md']
  spec.test_files = ['spec/*']
  spec.require_paths = ['lib']
  spec.license = 'Apache'
  spec.add_dependency 'cocoapods', '~> 1.0'
end
