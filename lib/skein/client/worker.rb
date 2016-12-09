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

        Skein::Adapter.subscribe(@queue) do |payload, delivery_tag, reply_to|
          @handler.handle(payload) do |reply_json|
            channel.acknowledge(delivery_tag, true)

            if (reply_to)
              @reply_exchange.publish(
                reply_json,
                routing_key: reply_to,
                content_type: 'application/json'
              )
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
end
