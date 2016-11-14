require 'securerandom'
require 'fiber'

class Skein::Client
  # == Properties ===========================================================

  attr_reader :context
  attr_reader :ident

  # == Instance Methods =====================================================

  def initialize(queue_name)
    @context = Skein::Context.new
    @ident = @context.ident(self)

    @channel = @context.channel
    @rpc_queue = @channel.queue(queue_name, durable: true)
    @response_queue = @channel.queue(@ident, durable: true, header: true, auto_delete: true)

    @threads = { }

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

    @context.connection.close
    @context = nil
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
