require_relative '../helper'

class ExampleWorker < Skein::Client::Worker
  attr_reader :initialized

  def after_initialize
    @initialized = true
  end
end

class TestSkeinWorker < Test::Unit::TestCase
  def test_default
    client = Skein::Client.new

    worker = client.worker('test_queue')

    assert worker

    assert_equal false, worker.async?

  ensure
    client and client.close
  end

  def test_subclass_initialize
    client = Skein::Client.new

    worker = ExampleWorker.new('test_queue', connection: client.connection)

    assert worker

    assert_equal false, worker.async?
    assert_equal true, worker.initialized

  ensure
    client and client.close
  end
end
