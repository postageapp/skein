require 'json'

class Skein::Client::Worker < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name, connection: nil, context: nil)
    super(connection: connection, context: context)

    lock do
      queue = self.channel.queue(queue_name, durable: true)

      @handler = Skein::Handler.for(self)

      @subscriber = Skein::Client::Subscriber.new(queue_name, connection: self.connection)

      @thread = Thread.new do
        @subscriber.listen do |payload, delivery_tag, reply_to|
          @handler.handle(payload) do |reply_json|
            channel.acknowledge(delivery_tag, true)

            if (reply_to)
              channel.default_exchange.publish(
                reply_json,
                routing_key: reply_to
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

protected
end
