require 'json'

class Skein::Client::Worker < Skein::Connected
  # == Instance Methods =====================================================

  def initialize(queue_name, exchange_name: nil, connection: nil, context: nil, concurrency: nil, durable: nil, auto_delete: false, routing_key: nil)
    super(connection: connection, context: context)

    @queue_name = queue_name
    concurrency &&= concurrency.to_i
    @threads = [ ]
    @durable = durable.nil? ? !!@queue_name.match(/\S/) : !!durable

    (concurrency || 1).times do |i|
      with_channel_in_thread do |channel|
        queue = channel.queue(
          @queue_name,
          durable: @durable,
          auto_delete: auto_delete
        )

        if (exchange_name and exchange_name.match(/S/))
          exchange = channel.direct(exchange_name, durable: true)

          queue.bind(exchange, routing_key: routing_key || @queue_name)
        end

        sync = concurrency && Queue.new

        Thread.current[:subscriber] = Skein::Adapter.subscribe(queue) do |payload, delivery_tag, reply_to|
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

            sync and sync << nil
          end

          sync and sync.pop
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
      subscriber = thread[:subscriber]
      if (subscriber.respond_to?(:gracefully_shut_down))
        subscriber.gracefully_shut_down
      end

      thread.respond_to?(:terminate!) ? thread.terminate! : thread.kill
      thread.join
    end

    if (delete_queue)
      # The connection may have been terminated, so reconnect and delete
      # the queue if necessary.
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

      begin
        yield(thread_channel)
      ensure
        # NOTE: The `.close` call may fail for a variety of reasons, but the
        #       important thing here is an attempt is made, regardless of
        #       outcome.
        thread_channel.close rescue nil
      end
    end
  end

  def handler
    @handler ||= Skein::Handler.for(self)
  end
end
