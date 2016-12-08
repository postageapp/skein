require 'json'

class Skein::Client::Worker < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name, exchange_name: nil, connection: nil, context: nil)
    super(connection: connection, context: context)

    lock do
      @reply_exchange = self.channel.default_exchange
      @queue = self.channel.queue(queue_name, durable: true)

      if (exchange_name)
        @exchange = self.channel.direct(exchange_name, durable: true)

        @queue.bind(@exchange)
      end

      @handler = Skein::Handler.for(self)

      @thread = Thread.new do
        Thread.abort_on_exception = true

        listen do |payload, delivery_tag, reply_to|
          @handler.handle(payload) do |reply_json|
            channel.acknowledge(delivery_tag, true)

            if (reply_to)
              p @reply_exchange
              @reply_exchange.publish(
                reply_json,
                routing_key: reply_to,
                content_type: 'application/json'
              )

              puts reply_json
              puts '-> %s' % reply_to
            end
          end
        end
      end
    end
  end

  def close
    @thread.kill
    @thread.join

    super
  end

  def join
    @thread and @thread.join
  end

  def async?
    # Define this method as `true` in any subclass that requires async
    # callback-style delegation.
    false
  end

protected
  def listen
    case (@queue.class.to_s.split(/::/)[0])
    when 'Bunny'
      @queue.subscribe(block: true) do |delivery_info, properties, payload|
        yield(payload, delivery_info[:delivery_tag], properties[:reply_to])
      end
      puts 'HUH??'
    when 'MarchHare'
      @queue.subscribe(block: true) do |metadata, payload|
        yield(payload, metadata.delivery_tag, metadata.reply_to)
      end
    end
  end
end
