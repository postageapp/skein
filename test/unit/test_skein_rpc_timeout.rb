require_relative '../helper'

class TestSkeinRpcTimeout< Test::Unit::TestCase
  def test_low_timeout
    assert_raise ThreadError do
      client = Skein::Client.new

      result = client.rpc('', routing_key: "test", timeout: 0.1).test
    end
  end

  def test_short_timeout
    assert_raise ThreadError do
      client = Skein::Client.new

      result = client.rpc('', routing_key: "test", timeout: 2).test
    end
  end
end
