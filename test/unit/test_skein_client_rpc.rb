require_relative '../helper'

class ExampleWorker < Skein::Client::Worker
  def echo(*args)
    args
  end

  def pops_exception
    invalid_code!
  end
end

class TestSkeinPublisher < Test::Unit::TestCase
  def setup
    @test_queue = 'rpc_test_q'

    @rpc = Skein::Client::RPC.new('', routing_key: @test_queue)
    @worker = ExampleWorker.new(@test_queue)
  end

  def teardown
    @rpc and @rpc.close
    @worker and @worker.close
  end

  def test_can_echo
    result = @rpc.echo('example')

    assert_equal %w[ example ], result
  end

  def test_can_handle_exceptions
    assert_raise_kind_of(NoMethodError) do
      @rpc.pops_exception
    end
  end
end
