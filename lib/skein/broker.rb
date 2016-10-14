require 'json'

class Skein::Broker
  # == Properties ===========================================================

  attr_reader :receiver

  # == Instance Methods =====================================================

  def initialize(receiver, reporter = nil)
    @receiver = receiver
    @reporter = reporter
  end

  def handle(message_json)
    request = JSON.load(message_json)

    request['params'] =
      case (params = request['params'])
      when Array
        params
      when nil
        request.key?('params') ? [ nil ] : [ ]
      else
        [ request['params'] ]
      end

    if (block_given?)
      # ...
    else
      begin
        JSON.dump(
          result: @receiver.send(request['method'], *request['params']),
          error: nil,
          id: request['id']
        )
      rescue Object => e
        @reporter and @reporter.exception!(e, message_json)

        JSON.dump(
          result: nil,
          error: '[%s] %s' % [ e.class, e ],
          id: request['id']
        )
      end
    end
  end
end
