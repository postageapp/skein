#!/usr/bin/env ruby

require 'rake/testtask'

# -- test/unit --------------------------------------------------------------

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/test*.rb']
  t.verbose = true
  t.warning = !!ENV['RUBY_WARN']
end

task default: :test
