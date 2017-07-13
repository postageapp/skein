require 'securerandom'
require 'fiber'

class Skein::Client::RPC < Skein::Connected
  # == Constants ============================================================

  EXCHANGE_NAME_DEFAULT = ''.freeze

  # == Properties ===========================================================

  # == Instance Methods =====================================================

  def initialize(exchange_name = nil, routing_key: nil, connection: nil, context: nil)
    super(connection: connection, context: context)

    @rpc_exchange = self.channel.direct(exchange_name || EXCHANGE_NAME_DEFAULT, durable: true)
    @routing_key = routing_key
    @response_queue = self.channel.queue(
      @ident,
      durable: false,
      header: true,
      auto_delete: true
    )

    @callback = { }

    @consumer = Skein::Adapter.subscribe(@response_queue, block: false) do |payload, delivery_tag, reply_to|
      self.context.trap do
        response = JSON.load(payload)

        if (callback = @callback.delete(response['id']))
          case (callback)
          when Queue
            callback << response['result']
          when Proc
            callback.call
          end
        end

        self.channel.acknowledge(delivery_tag)
      end
    end
  end

  def close
    @consumer and @consumer.cancel
    @consumer = nil

    super
  end

  def method_missing(name, *args)
    name = name.to_s

    blocking = !name.sub!(/!\z/, '')

    message_id = SecureRandom.uuid
    request = JSON.dump(
      jsonrpc: '2.0',
      method: name,
      params: args,
      id: message_id
    )

    @rpc_exchange.publish(
      request,
      routing_key: @routing_key,
      reply_to: blocking ? @ident : nil,
      content_type: 'application/json',
      message_id: message_id
    )

    if (block_given?)
      @callback[message_id] =
        if (defined?(EventMachine))
          EventMachine.next_tick do
            yield
          end
        else
          lambda do
            yield
          end
        end
    elsif (blocking)
      queue = Queue.new

      @callback[message_id] = queue

      queue.pop
    end
  end
end
