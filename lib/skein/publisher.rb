class Skein::Publisher
  # == Instance Methods =====================================================

  def initialize(queue_name)
    @context = Skein::Context.new
    @channel = @context.channel

    @queue = @channel.fanout(queue_name)
  end

  def publish!(message)
    @queue.publish(JSON.dump(message))
  end
  alias_method :<<, :publish!
end
