require 'json'

class Skein::Client::Worker < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name, exchange_name: nil, connection: nil, context: nil, concurrency: nil)
    super(connection: connection, context: context)

    lock do
      @reply_exchange = self.channel.default_exchange
      @queue = self.channel.queue(queue_name, durable: !!queue_name.match(/\S/))

      if (exchange_name)
        @exchange = self.channel.direct(exchange_name, durable: true)

        @queue.bind(@exchange)
      end

      @handler = Skein::Handler.for(self)
      @received = Queue.new
      @replies = Queue.new
      @concurrency = concurrency && concurrency.to_i || 1
      @threads = [ ]

      @threads << Thread.new do
        Thread.abort_on_exception = true

        Skein::Adapter.subscribe(@queue) do |payload, delivery_tag, reply_to|
          @received << [ payload, delivery_tag, reply_to ]
        end
      end

      @threads << Thread.new do
        Thread.abort_on_exception = true

        loop do
          payload, delivery_tag, reply_to, reply_json = @replies.pop

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

      @concurrency.times do
        @threads << Thread.new do
          Thread.abort_on_exception = true

          loop do
            payload, delivery_tag, reply_to = @received.pop
            thread = Thread.current

            @handler.handle(payload) do |reply_json|
              @replies << [ payload, delivery_tag, reply_to, reply_json ]

              if (thread == Thread.current)
                thread = nil
              else
                thread.wakeup
              end
            end

            thread and Thread.stop
          end
        end
      end
    end

    self.after_initialize
  end

  # Extend this in derived classes to implement any desired customization to
  # be performed after initialization
  def after_initialize
  end

  def close
    @threads.each do |thread|
      thread.kill
      thread.join
    end

    super
  end

  def join
    @threads.each do |thread|
      thread.join
    end
  end

  def async?
    # Define this method as `true` in any subclass that requires async
    # callback-style delegation.
    false
  end
end
