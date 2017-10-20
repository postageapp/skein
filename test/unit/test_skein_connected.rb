require_relative '../helper'

class TestSkeinConnected < Test::Unit::TestCase
  def test_construct_with_defaults
    connected = Skein::Connected.new

    assert connected

    assert connected.context
    assert connected.ident
    assert connected.connection
  end

  def test_construct_with_ident
    ident = ('test-%s' % SecureRandom.uuid).freeze
    connected = Skein::Connected.new(ident: ident)

    assert connected
    assert_equal ident, connected.ident
  end
end
