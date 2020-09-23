class Skein::Client::Publisher < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(exchange_name, type: nil, durable: nil, connection: nil, context: nil)
    super(connection: connection, context: context)

    @queue = self.channel.send(type || :topic, exchange_name, durable: durable)
  end

  def publish!(message, routing_key = nil)
    @queue.publish(JSON.dump(message), routing_key: routing_key)
  end
  alias_method :<<, :publish!

  def close(delete_queue: false)
    if (delete_queue)
      @queue.delete
    end

    super()
  end
end
