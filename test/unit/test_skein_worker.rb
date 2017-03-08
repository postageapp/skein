require_relative '../helper'

class TestSkeinWorker  < Test::Unit::TestCase
  def test_default
    client = Skein::Client.new

    worker = client.worker('test_queue')

    assert worker

    assert_equal false, worker.async?

  ensure
    client and client.close
  end
end
