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

    @response_queue = @channel.queue(@ident, durable: true, auto_delete: true)

    @threads = { }

    @response_queue.subscribe do |delivery_info, properties, payload|
      begin
        response = JSON.load(payload)

        if (thread = @threads.delete(response['id']))
          thread[:result] = response['result']

          thread.wakeup
        end
      rescue => e
        puts e.inspect
      end
    end
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

    @threads[message_id] = Thread.current

    Thread.stop

    Thread.current[:result]
  end
end
