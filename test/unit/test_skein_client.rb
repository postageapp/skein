require_relative '../helper'

class TestSkeinClient < Test::Unit::TestCase
  def test_default
    client = nil

    assert_no_threads do
      begin
        client = Skein::Client.new

        assert client.context
        assert_false client.connection_shared?

        client&.close

      ensure
        client&.close
      end
    end
  end
end
