class Skein::Client::Subscriber < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(exchange, routing_key = nil, connection: nil, context: nil)
    super(connection: connection, context: context)

    @exchange =
      case (exchange)
      when String, Symbol
        self.channel.topic(exchange)
      else
        exchange
      end

    @subscribe_queue = self.channel.queue('', exclusive: true, durable: false)
    @subscribe_queue.bind(@exchange, routing_key: routing_key)
  end

  def listen(block = true)
    case (@subscribe_queue.class.to_s.split(/::/)[0])
    when 'Bunny'
      @subscribe_queue.subscribe(block: block) do |delivery_info, properties, payload|
        yield(JSON.load(payload), delivery_info, properties)
      end
    when 'MarchHare'
      @subscribe_queue.subscribe(block: block) do |metadata, payload|
        yield(JSON.load(payload), metadata)
      end
    else
      raise "Unknown queue type #{@subscribe_queue.class}, cannot listen."
    end
  end

  def close(delete_queue: false)
    if (delete_queue)
      @subscribe_queue.delete
    end

    super()
  end
end
