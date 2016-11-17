require_relative '../helper'

class TestSkeinReceiver < Test::Unit::TestCase
  def test_base
    receiver = Skein::Receiver.new

    assert_equal(receiver.ident, Skein::Context.default.ident(receiver))
    assert_equal(Skein::Context.default, receiver.context)
  end

  def test_with_context
    context = Skein::Context.new(
      hostname: 'test_skein_receiver.host',
      process_name: 'test_with_context_and_ident',
      process_id: 2910
    )

    receiver = Skein::Receiver.new(context)

    assert_equal(context, receiver.context)
    assert_equal(context.ident(receiver), receiver.ident)
  end

  def test_with_ident
    ident = '90ea4fe5-c9f4-47d0-819a-c68ee6de656f'

    receiver = Skein::Receiver.new(nil, ident)

    assert_equal(Skein::Context.default, receiver.context)
    assert_equal(ident, receiver.ident)
  end

  def test_with_context_and_ident
    context = Skein::Context.new(
      hostname: 'test_skein_receiver.host',
      process_name: 'test_with_context_and_ident',
      process_id: 2910
    )
    ident = '7537aff1-e61a-4105-b9bf-c81f8eb5d8cf'
    receiver = Skein::Receiver.new(context, ident)

    assert_equal(context, receiver.context)
    assert_equal(ident, receiver.ident)
  end
end
