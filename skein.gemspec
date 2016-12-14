# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: skein 0.3.2 ruby lib

Gem::Specification.new do |s|
  s.name = "skein".freeze
  s.version = "0.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Scott Tadman".freeze]
  s.date = "2016-12-14"
  s.description = "Wrapper for RabbitMQ that makes blocking RPC calls and handles pub-sub broadcasts.".freeze
  s.email = "tadman@postageapp.com".freeze
  s.executables = ["skein".freeze]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "README.md",
    "RELEASES.md",
    "Rakefile",
    "VERSION",
    "bin/skein",
    "config/.gitignore",
    "config/skein.yml.example",
    "lib/skein.rb",
    "lib/skein/adapter.rb",
    "lib/skein/client.rb",
    "lib/skein/client/publisher.rb",
    "lib/skein/client/rpc.rb",
    "lib/skein/client/subscriber.rb",
    "lib/skein/client/worker.rb",
    "lib/skein/config.rb",
    "lib/skein/connected.rb",
    "lib/skein/context.rb",
    "lib/skein/handler.rb",
    "lib/skein/handler/async.rb",
    "lib/skein/handler/threaded.rb",
    "lib/skein/rabbitmq.rb",
    "lib/skein/reporter.rb",
    "lib/skein/rpc.rb",
    "lib/skein/rpc/base.rb",
    "lib/skein/rpc/error.rb",
    "lib/skein/rpc/notification.rb",
    "lib/skein/rpc/request.rb",
    "lib/skein/rpc/response.rb",
    "lib/skein/support.rb",
    "skein.gemspec",
    "test/data/sample_config.yml",
    "test/helper.rb",
    "test/script/em_example",
    "test/unit/test_skein_client.rb",
    "test/unit/test_skein_client_publisher.rb",
    "test/unit/test_skein_client_subscriber.rb",
    "test/unit/test_skein_client_worker.rb",
    "test/unit/test_skein_config.rb",
    "test/unit/test_skein_context.rb",
    "test/unit/test_skein_rabbitmq.rb",
    "test/unit/test_skein_reporter.rb",
    "test/unit/test_skein_rpc_error.rb",
    "test/unit/test_skein_rpc_request.rb",
    "test/unit/test_skein_support.rb",
    "tmp/.gitignore"
  ]
  s.homepage = "http://github.com/postageapp/skein".freeze
  s.licenses = ["closed".freeze]
  s.rubygems_version = "2.5.2".freeze
  s.summary = "RabbitMQ RPC/PubSub Library".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<birling>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<jeweler>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
    else
      s.add_dependency(%q<birling>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<jeweler>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<birling>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<jeweler>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end

