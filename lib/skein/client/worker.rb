require 'json'

class Skein::Client::Worker < Skein::Connected
  # == Properties ===========================================================

  attr_reader :operations

  # == Class Methods ========================================================

  # == Instance Methods =====================================================

  def initialize(queue_name, exchange_name: nil, connection: nil, context: nil, concurrency: nil, durable: nil, auto_delete: false, routing_key: nil)
    super(connection: connection, context: context)

    @exchange_name = exchange_name
    @queue_name = queue_name
    concurrency &&= concurrency.to_i
    @operations = [ ]
    @durable = durable.nil? ? !!@queue_name.match(/\S/) : !!durable

    (concurrency || 1).times do |i|
      with_channel_in_thread do |channel, meta|
        queue = channel.queue(
          @queue_name,
          durable: @durable,
          auto_delete: auto_delete
        )

        if (exchange_name and exchange_name.match(/S/))
          exchange = channel.direct(exchange_name, durable: true)

          queue.bind(exchange, routing_key: routing_key || @queue_name)
        end

        meta[:subscriber] = Skein::Adapter.subscribe(queue) do |payload, delivery_tag, reply_to|
          self.context.trap do
            self.before_request

            handler.handle(payload, meta[:metrics], meta[:state]) do |reply_json|
              self.context.trap do
                channel.acknowledge(delivery_tag, true)

                if (reply_to)
                  channel.default_exchange.publish(
                    reply_json,
                    routing_key: reply_to,
                    content_type: 'application/json'
                  )
                end

                self.after_request
              end
            end
          end
        end
      end
    end

    self.after_initialize
  end

  # Define in derived classes to implement any desired customization to be
  # performed after initialization.
  def after_initialize
  end

  # Define in derived classes. Willl be called immediately after a request is
  # received but before any processing occurs.
  def before_request
  end

  # Define in derived classes. Will be called immediately prior to executing
  # the worker method.
  def before_execution(method_name)
  end

  # Define in derived classes. Will be called immediately after executing the
  # worker method.
  def after_execution(method_name)
  end

  # Define in derived classes. Will be called immediately after handling an
  # RPC call even if an error has occured.
  def after_request
  end

  def close(delete_queue: false)
    @operations.each do |meta|
      subscriber = meta[:subscriber]

      if (subscriber.respond_to?(:gracefully_shut_down))
        subscriber.gracefully_shut_down
      end

      thread = meta[:thread]

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
    @operations.each do |meta|
      meta[:thread].join
    end
  end

  def async?
    # Define this method as `true` in any subclass that requires async
    # callback-style delegation.
    false
  end

  # Signal that the current operation should be abandoned and retried later.
  def force_retry!
    # ...!
  end

protected
  def state_tracker
    {
      method: nil,
      started: nil,
      finished: nil
    }
  end

  def metrics_tracker
    Hash.new(0).merge(
      time: 0.0,
      errors: Hash.new(0)
    )
  end

  def in_thread
    @operations << {
      thread: Thread.new do
        Thread.abort_on_exception = true

        yield
      end
    }
  end

  def with_channel_in_thread
    thread_channel = @connection.create_channel

    meta = {
      metrics: metrics_tracker,
      state: state_tracker
    }

    @operations << meta

    meta[:thread] = Thread.new do
      Thread.abort_on_exception = true

      begin
        yield(thread_channel, meta)

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
