require_relative '../helper'

class TestSkeinClientSubscriber < Test::Unit::TestCase
  def test_cycle
    client = Skein::Client.new

    publisher = client.publisher('test')

    received = nil

    subscriber = client.subscriber('test', '*.*') 
    subscribing = false

    thread = Thread.new do
      Thread.abort_on_exception = true

      subscribing = true

      subscriber.listen do |payload|
        received = payload

        Thread.exit
      end
    end

    while (!subscribing)
      # Spin-lock to wait for the subscriber to come online
    end

    publisher.publish!({ data: true }, 'test.notification')

    thread.join

    assert_equal({ "data" => true }, received)

  ensure
    publisher and publisher.close
    subscriber and subscriber.close
    client and client.close
  end
end
