require_relative '../helper'

class TestSkeinPublisher < Test::Unit::TestCase
  def test_defaults
    publisher = Skein::Client::Publisher.new('test_name')

  ensure
    publisher and publisher.close(delete_queue: true)
  end
end
