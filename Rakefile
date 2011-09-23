require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

[:mysql, :mysql2, :jdbcmysql, :postgresql].each do |adapter|
  desc "Run specs for #{adapter} adapter"
  RSpec::Core::RakeTask.new("spec:#{adapter.to_s}") do |t|
    t.pattern = "spec/#{adapter}_spec.rb"
  end
end
