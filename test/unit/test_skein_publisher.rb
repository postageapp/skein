require_relative '../helper'

class TestSkeinPublisher < Test::Unit::TestCase
  def test_defaults
    publisher = Skein::Publisher.new('test_name')

  ensure
    publisher and publisher.close
  end
end
