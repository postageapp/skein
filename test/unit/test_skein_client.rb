require_relative '../helper'

class TestSkeinClient < Test::Unit::TestCase
  def test_default
    client = Skein::Client.new

    assert client.context
  end
end
