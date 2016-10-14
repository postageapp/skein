require_relative '../helper'

class TestSkeinContext < Test::Unit::TestCase
  def test_default
    context = Skein::Context.default

    assert(context)

    assert_equal(Skein::Support.hostname, context.hostname)
    assert_equal(Skein::Support.process_name, context.process_name)
    assert_equal(Skein::Support.process_id, context.process_id)
  end

  def test_defaults
    context = Skein::Context.new

    assert_equal(Skein::Support.hostname, context.hostname)
    assert_equal(Skein::Support.process_name, context.process_name)
    assert_equal(Skein::Support.process_id, context.process_id)
  end

  def test_override
    context = Skein::Context.new(
      hostname: 'sample.host',
      process_name: 'test_process',
      process_id: 20301
    )

    assert_equal('sample.host', context.hostname)
    assert_equal('test_process', context.process_name)
    assert_equal(20301, context.process_id)
  end

  def test_generate_ident
    context = Skein::Context.new

    ident = context.ident(self)

    assert(ident)

    assert_not_equal(ident, context.ident(context))
    assert_equal(ident, context.ident(self))
  end
end
