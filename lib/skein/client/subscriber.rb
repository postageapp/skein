class Skein::Client::Subscriber < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name, connection: nil, context: nil)
    super(connection: connection, context: context)

    @queue = self.channel.fanout(queue_name)
    @subscribe_queue = self.channel.queue('', exclusive: true)

    @subscribe_queue.bind(@queue)
  end

  def listen
    @subscribe_queue.subscribe(block: true) do |*args|
      # REFACTOR: Fix decoding here on JSON payload
      # REFACTOR: Abstract out differences between Bunny and MarchHare
      yield(*args)
    end
  end
end
