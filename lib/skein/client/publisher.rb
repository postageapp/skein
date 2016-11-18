class Skein::Client::Publisher < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name, connection: nil, context: nil)
    super(connection: connection, context: context)

    @queue = self.channel.fanout(queue_name)
  end

  def publish!(message)
    @queue.publish(JSON.dump(message))
  end
  alias_method :<<, :publish!
end
