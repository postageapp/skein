#!/usr/bin/env ruby

require 'rake/testtask'

# -- Jeweler ----------------------------------------------------------------

require 'jeweler'

Jeweler::Tasks.new do |gem|
  gem.name = 'skein'
  gem.homepage = 'http://github.com/postageapp/skein'
  gem.license = 'MIT'
  gem.summary = %Q{RabbitMQ RPC/PubSub Library}
  gem.description = %Q{Wrapper for RabbitMQ that makes blocking RPC calls and handles pub-sub broadcasts.}
  gem.email = 'tadman@postageapp.com'
  gem.authors = [ 'Scott Tadman' ]
end

Jeweler::RubygemsDotOrgTasks.new

# -- test/unit --------------------------------------------------------------

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/test*.rb']
  t.verbose = true
  t.warning = !!ENV['RUBY_WARN']
end

task default: :test
