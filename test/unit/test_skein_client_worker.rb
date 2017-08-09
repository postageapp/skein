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
    worker = ErrorGenerator.new('test_rpc')
    handler = worker.send(:handler)

    message = {
      method: 'ident',
      params: [ ],
      id: '43d8352c-4907-4c32-9c81-fc34e91a3884'
    }

    metrics = worker.send(:metrics_tracker)
    state = worker.send(:state_tracker)

    handler.handle(JSON.dump(message), metrics, state) do |response_json, error|
      response = JSON.load(response_json)

      expected = {
        'jsonrpc' => '2.0',
        'result' => worker.ident,
        'id' => message[:id]
      }

      assert_equal(expected, response)
    end

  ensure
    worker and worker.close(delete_queue: true)
  end

  def test_throws_exception
    worker = ErrorGenerator.new('test_error')
    handler = Skein::Handler.for(worker)

    message = {
      method: 'raises_error',
      id: '29fe8a40-fccf-43c6-ba48-818598c66e6f'
    }

    metrics = worker.send(:metrics_tracker)
    state = worker.send(:state_tracker)

    handler.handle(JSON.dump(message), metrics, state) do |response_json, error|
      expected = {
        'jsonrpc' => '2.0',
        'error' => {
          'code' => -32063,
          'message' => '[TestSkeinClientWorker::ErrorGenerator::CustomError] Example error!'
        },
        'id' => message[:id]
      }

      assert_equal(expected.to_json, response_json)

      assert_equal(1, metrics[:failed])
      assert_equal(1, metrics[:errors][:exception])
      assert(metrics[:time] >= 0, 'Time (%.3f) should be positive' % metrics[:time])
    end

  ensure
    worker and worker.close(delete_queue: true)
  end
end
