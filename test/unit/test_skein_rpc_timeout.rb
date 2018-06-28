require_relative '../helper'

class TestSkeinRpcTimeout< Test::Unit::TestCase
  def test_default
    assert_raise ThreadError do
      client = Skein::Client.new

      result = client.rpc('', routing_key: "test", timeout: 0.1).test
    end
  end

  def test_ten_seconds
    assert_raise ThreadError do
      client = Skein::Client.new

      result = client.rpc('', routing_key: "test", timeout: 10).test
    end
  end
end
