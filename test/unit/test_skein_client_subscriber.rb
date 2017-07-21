require_relative '../helper'

class TestSkeinClientSubscriber < Test::Unit::TestCase
  def test_immediate_close
    client = Skein::Client.new

    received = nil

    subscriber = client.subscriber('test', '*.*') 
    subscribing = false

    thread = in_thread do
      subscribing = true

      subscriber.listen do |payload|
        received = payload
      end
    end

    while (!subscribing)
      # Spin-lock to wait for the subscriber to come online
    end

  ensure
    subscriber and subscriber.close(delete_queue: true)
    client and client.close
  end

  def test_cycle
    client = Skein::Client.new

    publisher = client.publisher('test')

    received = nil

    subscriber = client.subscriber('test', '*.*') 
    subscribing = false

    thread = in_thread do
      subscribing = true

      subscriber.listen do |payload|
        received = payload
      end
    end

    wait_for { subscribing }

    publisher.publish!({ data: true }, 'test.notification')

    wait_for { received }

    assert_equal({ 'data' => true }, received)

  ensure
    publisher and publisher.close(delete_queue: true)
    subscriber and subscriber.close(delete_queue: true)
    client and client.close
  end
end
