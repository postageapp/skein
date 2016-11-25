class Skein::Client::Subscriber < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name, connection: nil, context: nil)
    super(connection: connection, context: context)

    @queue = self.channel.fanout(queue_name)
    @subscribe_queue = self.channel.queue('', exclusive: true)

    @subscribe_queue.bind(@queue)
  end

  def listen
    case (@subscribe_queue.class.to_s.split(/::/)[0])
    when 'Bunny'
      @subscribe_queue.subscribe(block: true) do |delivery_info, properties, payload|
        yield(JSON.load(payload), delivery_info, properties)
      end
    when 'MarchHare'
      @subscribe_queue.subscribe(block: true) do |metadata, payload|
        yield(JSON.load(payload), metadata)
      end
    end
  end
end
