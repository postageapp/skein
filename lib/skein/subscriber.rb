class Skein::Subscriber < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name)
    super()

    @queue = self.channel.fanout(queue_name)
    @subscribe_queue = self.channel.queue('', exclusive: true)

    @subscribe_queue.bind(@queue)
  end

  def listen
    @subscribe_queue.subscribe(block: true) do |*args|
      yield(*args)
    end
  end
end
