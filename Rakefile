require 'rake/testtask'

require "bundler/gem_tasks"

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.test_files = FileList['test/plugin/*.rb']
  test.verbose = true
end

task :default => :test