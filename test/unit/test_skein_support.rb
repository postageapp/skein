require_relative '../helper'

class TestSkeinSupport < Test::Unit::TestCase
  def test_symbolize_keys_simple_hash
    hash = {
      'test' => 'test_value',
      true => 'true_value',
      2 => 'two'
    }

    expected = {
      test: 'test_value',
      true: 'true_value',
      '2': 'two'
    }

    assert_equal(expected, Skein::Support.symbolize_keys(hash))
  end

  def test_symbolize_keys_on_array
    array = [
      {
        'test' => :value,
        'nested' => {
          'hash' => true
        }
      },
      {
        'second' => :hash
      }
    ]

    expected = [
      {
        test: :value,
        nested: {
          hash: true
        }
      },
      {
        second: :hash
      }
    ]

    assert_equal(expected, Skein::Support.symbolize_keys(array))
  end

  def test_symbolize_keys_on_non_hashes
    assert_mapping(
      1 => 1,
      true => true,
      nil => nil,
      'test' => 'test',
      :symbol => :symbol
    ) do |value|
      Skein::Support.symbolize_keys(value)
    end
  end

  def test_hostname
    hostname = Skein::Support.hostname

    assert_equal(String, hostname.class)
    assert(hostname.length > 0)
  end

  def test_process_name
    process_name = Skein::Support.process_name

    assert(process_name)

    assert(%w[ test_skein_support rake_test_loader ].include?(process_name))
  end

  def test_pid
    process_id = Skein::Support.process_id

    assert(process_id)
    assert(process_id.is_a?(Integer))
  end
end
