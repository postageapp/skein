require 'json'

class Skein::Broker
  # == Properties ===========================================================

  attr_reader :receiver

  # == Instance Methods =====================================================

  def initialize(receiver, reporter = nil)
    @receiver = receiver
    @reporter = reporter
  end

  def listen(channel, queue)
    queue.subscribe(manual_ack: true, block: true, headers: true) do |metadata, payload, extra|
      reply_to = nil
      headers = nil

      # NOTE: Bunny and MarchHare deal with this in a slightly different
      #       capcity where the reply_to header is moved around.
      if (extra)
        headers = payload
        payload = extra

        reply_to = headers[:reply_to]
      else
        reply_to = metadata.reply_to
      end

      reply = handle(payload)

      channel.acknowledge(metadata.delivery_tag, true)

      channel.default_exchange.publish(
        reply,
        routing_key: reply_to
      )
    end
  end

  def handle(message_json)
    # REFACTOR: Use Skein::RPC::Request
    request =
      begin
        JSON.load(message_json)

      rescue Object => e
        @reporter and @reporter.exception!(e, message_json)

        return JSON.dump(
          result: nil,
          error: '[%s] %s' % [ e.class, e ],
          id: request['id']
        )
      end

    case (request)
    when Hash
      # Acceptable
    else
      return JSON.dump(
        result: nil,
        error: 'Request does not conform to the JSON-RPC format.',
        id: nil
      )
    end

    request['params'] =
      case (params = request['params'])
      when Array
        params
      when nil
        request.key?('params') ? [ nil ] : [ ]
      else
        [ request['params'] ]
      end

    unless (request['method'] and request['method'].is_a?(String) and request['method'].match(/\S/))
      return JSON.dump(
        result: nil,
        error: 'Request does not conform to the JSON-RPC format, missing valid method.',
        id: request['id']
      )
    end

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
