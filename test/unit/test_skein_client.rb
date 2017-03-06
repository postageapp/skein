require_relative '../helper'

class TestSkeinClient < Test::Unit::TestCase
  def test_default
    client = nil

    assert_no_threads do
      begin
        client = Skein::Client.new

        assert client.context

      ensure
        client and client.close
      end
    end
  end
end
