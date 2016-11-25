require_relative '../helper'

class TestSkeinClient < Test::Unit::TestCase
  def test_default
    client = nil

    assert_no_threads do
      client = Skein::Client.new

      assert client.context

      client.close
    end

  # ensure
  #   client and client.close
  end
end
