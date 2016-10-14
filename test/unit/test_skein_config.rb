require_relative '../helper'

class TestSkeinConfig < Test::Unit::TestCase
  def test_env
    assert_equal('test', Skein::Config.env)
  end

  def test_default_state
    config = Skein::Config.new(false)

    assert config

    assert_equal('127.0.0.1', config.host)
    assert_equal(5672, config.port)
    assert_equal('guest', config.username)
    assert_equal('guest', config.password)
    assert_equal(nil, config.namespace)
  end

  def test_with_config_path
    config = Skein::Config.new(data_path('sample_config.yml'))

    assert_equal('test.host', config.host)
    assert_equal(5670, config.port)
    assert_equal('test_user', config.username)
    assert_equal('test_password', config.password)
    assert_equal('test', config.namespace)
  end

  def test_config_exists
    assert_equal(true, Skein::Config.exist?)
  end
end
