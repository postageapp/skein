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
      begin
        @subscribe_queue.subscribe(block: block) do |delivery_info, properties, payload|
          yield(JSON.load(payload), delivery_info, properties)
        end
      end
    when 'MarchHare'
      begin
        @subscribe_queue.subscribe(block: block) do |metadata, payload|
          yield(JSON.load(payload), metadata)
        end
      rescue MarchHare::ChannelAlreadyClosed
        # Connection got killed outside of thread, so shut-down and move on
      end
    else
      raise "Unknown queue type #{@subscribe_queue.class}, cannot listen."
    end
  end

  def close(delete_queue: false)
    if (delete_queue)
      begin
        @subscribe_queue.delete
      rescue => e
        case (e.class.to_s)
        when 'Bunny::ChannelAlreadyClosed', 'MarchHare::ChannelAlreadyClosed'
          # Tried to delete, but this has already been shut down
        else
          raise e
        end
      end
    end

    super()
  end
end
