$:.unshift(File.join(File.dirname(__FILE__) ,'../../gems/georuby/lib/'))
require 'rubygems'
require 'spec/rake/spectask'
require 'jeweler'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end

Jeweler::Tasks.new do |gem|
  gem.name = "spatial_adapter"
  gem.summary = "Spatial Adapter for ActiveRecord"
  gem.description = "Provides enhancements to ActiveRecord to handle spatial datatypes in PostgreSQL and MySQL."
  gem.author = "Pete Deffendol"
  gem.email = "pete@fragility.us"
  gem.homepage = "http://github.com/fragility/spatial_adapter"
    
  # s.rubyforge_project = "thinking-sphinx"
  gem.files = FileList[
    "rails/*.rb",
    "lib/**/*.rb",
    "MIT-LICENSE",
    "README.rdoc",
    "VERSION"
  ]
  gem.test_files = FileList[
    "spec/**/*_spec.rb"
  ]
  
  gem.add_dependency 'activerecord', '>= 2.2.2'
  gem.add_dependency 'GeoRuby', '>= 1.3.0'
end
