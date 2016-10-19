require 'securerandom'
require 'fiber'

class Skein::Client
  # == Properties ===========================================================

  attr_reader :context
  attr_reader :ident

  # == Instance Methods =====================================================

  def initialize(context, rpc_queue)
    @context = context || Skein::Context.default
    @ident = @context.ident(self)

    @channel = rpc_queue.channel
    @rpc_queue = rpc_queue

    @response_queue = @channel.queue(@ident, durable: true, header: true, auto_delete: true)

    @threads = { }

    @consumer = @response_queue.subscribe do |metadata, payload, extra|
      # puts [metadata,payload,extra].inspect

      # puts [metadata,payload,extra].map(&:class).inspect

      if (extra)
        payload = extra
      elsif (!payload)
        payload = metadata
      end

      begin
        response = JSON.load(payload)

        if (queue = @threads.delete(response['id']))
          queue << response['result']
        end
      rescue => e
        # FIX: Error handling
        puts e.inspect
      end
    end
  end

  def cancel!
    @consumer and @consumer.cancel

    @consumer = nil
  end

  def method_missing(name, *args)
    message_id = SecureRandom.uuid
    request = JSON.dump(
      method: name,
      params: args,
      id: message_id
    )

    @channel.default_exchange.publish(
      request,
      routing_key: @rpc_queue.name,
      reply_to: @ident,
      message_id: message_id
    )

    queue = Queue.new

    @threads[message_id] = queue

    queue.pop
  end
end
