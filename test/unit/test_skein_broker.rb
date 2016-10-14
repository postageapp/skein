require_relative '../helper'

class TestSkeinBroker < Test::Unit::TestCase
  class ErrorGenerator < Skein::Receiver
    class CustomError < RuntimeError
    end

    def raises_error
      raise CustomError, 'Example error!'
    end
  end

  def test_example
    receiver = Skein::Receiver.new

    broker = Skein::Broker.new(receiver)

    assert_equal(receiver, broker.receiver)

    message = {
      method: 'ident',
      params: [ ],
      id: '43d8352c-4907-4c32-9c81-fc34e91a3884'
    }

    response = JSON.load(broker.handle(JSON.dump(message)))

    expected = {
      'result' => receiver.ident,
      'error' => nil,
      'id' => message[:id]
    }

    assert_equal(expected, response)
  end

  def test_throws_exception
    broker = Skein::Broker.new(ErrorGenerator.new)

    message = {
      method: 'raises_error',
      id: '29fe8a40-fccf-43c6-ba48-818598c66e6f'
    }

    response = JSON.load(broker.handle(JSON.dump(message)))

    expected = {
      'result' => nil,
      'error' => '[TestSkeinBroker::ErrorGenerator::CustomError] Example error!',
      'id' => message[:id]
    }

    assert_equal(expected, response)
  end
end
