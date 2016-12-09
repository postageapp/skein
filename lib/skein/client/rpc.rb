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
    @response_queue = self.channel.queue(@ident, durable: true, header: true, auto_delete: true)

    @callback = { }

    @consumer = @response_queue.subscribe do |metadata, payload, extra|
      # FIX: Deal with mixup between Bunny and MarchHare
      # puts [metadata,payload,extra].inspect

      # puts [metadata,payload,extra].map(&:class).inspect

      if (extra)
        payload = extra
      elsif (!payload)
        payload = metadata
      end

      begin
        response = JSON.load(payload)

        if (callback = @callback.delete(response['id']))
          case (callback)
          when Queue
            callback << response['result']
          when Proc
            callback.call
          end
        end
        
      rescue => e
        self.context and self.context.exception!(e)
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
