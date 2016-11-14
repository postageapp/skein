class Skein::Publisher < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name)
    super()

    @queue = self.channel.fanout(queue_name)
  end

  def publish!(message)
    @queue.publish(JSON.dump(message))
  end
  alias_method :<<, :publish!
end
