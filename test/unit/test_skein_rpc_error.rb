require_relative '../helper'

class TestSkeinRPCError < Test::Unit::TestCase
  def test_default
    error = Skein::RPC::Error.new

    assert_equal nil, error.id
    assert_equal nil, error.error
  end
end
