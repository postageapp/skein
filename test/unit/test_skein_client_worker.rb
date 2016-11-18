require_relative '../helper'

class TestSkeinClientWorker < Test::Unit::TestCase
  class ErrorGenerator < Skein::Client::Worker
    class CustomError < RuntimeError
    end

    def raises_error
      raise CustomError, 'Example error!'
    end
  end

  def test_example
    worker = Skein::Client::Worker.new('test_rpc')

    message = {
      method: 'ident',
      params: [ ],
      id: '43d8352c-4907-4c32-9c81-fc34e91a3884'
    }

    response = JSON.load(worker.send(:handle, JSON.dump(message)))

    expected = {
      'result' => worker.ident,
      'error' => nil,
      'id' => message[:id]
    }

    assert_equal(expected, response)
  end

  def test_throws_exception
    worker = ErrorGenerator.new('test_error')

    message = {
      method: 'raises_error',
      id: '29fe8a40-fccf-43c6-ba48-818598c66e6f'
    }

    response = JSON.load(worker.send(:handle, JSON.dump(message)))

    expected = {
      'result' => nil,
      'error' => '[TestSkeinClientWorker::ErrorGenerator::CustomError] Example error!',
      'id' => message[:id]
    }

    assert_equal(expected, response)
  end
end
