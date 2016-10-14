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


    consumer = @response_queue.subscribe(block: true) do |delivery_info, properties, payload|
      puts [ delivery_info, properties, payload ].inspect
      response = JSON.load(payload)

      # consumer.cancel

      response['result']
    end
  end
end
