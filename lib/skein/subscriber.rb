class Skein::Subscriber
  # == Instance Methods =====================================================

  def initialize(queue_name)
    @context = Skein::Context.default
    @channel = @context.channel

    @queue = @channel.fanout(queue_name)
    @subscribe_queue = @channel.queue('', exclusive: true)

    @subscribe_queue.bind(@queue)
  end

  def listen
    @subscribe_queue.subscribe(block: true) do |*args|
      yield(*args)
    end
  end
end
