require_relative '../helper'

class TestSkeinRabbitMQ < Test::Unit::TestCase
  def test_can_connect
    rmq = Skein::RabbitMQ.connect

    assert rmq

    assert rmq.respond_to?(:create_channel)

  ensure
    rmq and rmq.close
  end
end
