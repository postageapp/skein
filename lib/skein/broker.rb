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
    queue.subscribe(manual_ack: true, header: true, block: true) do |delivery_info, properties, payload|
      puts delivery_info.inspect
      puts payload.inspect

      reply = handle(payload)

      puts reply.inspect

      channel.acknowledge(delivery_info.delivery_tag, true)

      channel.default_exchange.publish(
        reply,
        routing_key: properties[:reply_to]
      )
    end
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
