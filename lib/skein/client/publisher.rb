class Skein::Client::Publisher < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name, connection: nil, context: nil)
    super(connection: connection, context: context)

    @queue = self.channel.topic(queue_name)
  end

  def publish!(message, routing_key = nil)
    @queue.publish(JSON.dump(message), routing_key: routing_key)
  end
  alias_method :<<, :publish!
end
