require 'json'

class Skein::Client::Worker < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name, exchange_name: nil, connection: nil, context: nil, concurrency: nil, durable: nil)
    super(connection: connection, context: context)

    @queue_name = queue_name
    concurrency = concurrency && concurrency.to_i || 1
    @threads = [ ]
    @durable = durable.nil? ? !!@queue_name.match(/\S/) : false

    concurrency.times do |i|
      queue = Queue.new

      with_channel_in_thread do |channel|
        queue = channel.queue(@queue_name, durable: @durable)

        if (exchange_name)
          exchange = channel.direct(exchange_name, durable: true)

          queue.bind(exchange)
        end

        sync = Queue.new

        Skein::Adapter.subscribe(queue) do |payload, delivery_tag, reply_to|
          self.before_request

          handler.handle(payload) do |reply_json|
            channel.acknowledge(delivery_tag, true)

            if (reply_to)
              channel.default_exchange.publish(
                reply_json,
                routing_key: reply_to,
                content_type: 'application/json'
              )
            end

            self.after_request

            sync << nil
          end

          sync.pop
        end
      end
    end

    self.after_initialize
  end

  # Extend this in derived classes to implement any desired customization to
  # be performed after initialization
  def after_initialize
  end

  # Extend this in derived classes to implement any behaviour that should be
  # triggered prior to handling a request.
  def before_request
  end

  # Extend this in derived classes to implement any behaviour that should be
  # triggered  after handling a request, even if an error occurred.
  def after_request
  end

  def close(delete_queue: false)
    @threads.each do |thread|
      thread.kill
      thread.join
    end

    if (delete_queue)
      channel = @connection.create_channel

      channel.queue(@queue_name, durable: @durable).delete

      channel.close
    end

    super()
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

protected
  def in_thread
    @threads << Thread.new do
      Thread.abort_on_exception = true

      yield
    end
  end

  def with_channel_in_thread
    thread_channel = @connection.create_channel

    @threads << Thread.new do
      Thread.abort_on_exception = true

      yield(thread_channel)

      thread_channel.close
    end
  end

  def handler
    @handler ||= Skein::Handler.for(self)
  end
end
