require 'json'

class Skein::Client::Worker < Skein::Connected
  # == Properties ===========================================================

  attr_reader :operations

  # == Exceptions ===========================================================

  class RejectMessage < Exception
  end

  class RetryMessage < Exception
  end

  # == Class Methods ========================================================

  # == Instance Methods =====================================================

  def initialize(queue_name, exchange_name: nil, connection: nil, context: nil, concurrency: nil, durable: nil, auto_delete: false, routing_key: nil, ident: nil)
    super(connection: connection, context: context, ident: ident)

    @exchange_name = exchange_name
    @queue_name = queue_name
    @routing_key = routing_key
    @durable = durable.nil? ? !!@queue_name.match(/\S/) : !!durable
    @operations = [ ]
    @auto_delete = auto_delete

    concurrency &&= concurrency.to_i
    concurrency ||= 1

    concurrency.times do |i|
      with_channel_in_thread(name: 'worker-%d' % i) do |channel, meta|
        self.establish_subscriber!(channel, meta)
      end
    end

    self.after_initialize rescue nil
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

  # Declared in derived classes. Will be called immediately after an
  # exception has occurred when processing a request. Any excepions generated
  # in this method call are suppressed and ignored to avoid being caught
  # in a loop.
  def after_exception(e)
  end

  # Declared in derived classes. Will be called immediately before the worker
  # is closed down.
  def before_close
  end

  # Declared in derived classes. Will be called immediately after the worker
  # has been closed down.
  def after_close
  end

  def close(delete_queue: false)
    self.before_close

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

    self.after_close
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

  # Signal that the current operation should be abandoned and not retried.
  def reject!
    raise RejectMessage
  end

  # Signal that the current operation should be abandoned and retried later.
  def retry!
    raise RetryMessage
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

  def establish_queue!(channel)
    queue = channel.queue(
      @queue_name,
      durable: @durable,
      auto_delete: @auto_delete
    )

    if (@exchange_name&.match(/\S/))
      exchange = channel.direct(@exchange_name, durable: true)

      queue.bind(exchange, routing_key: @routing_key || @queue_name)
    end

    queue
  end

  def establish_subscriber!(channel, meta)
    queue = self.establish_queue!(channel)

    meta[:subscriber] = Skein::Adapter.subscribe(queue) do |payload, delivery_tag, reply_to|
      if (ENV['SKEIN_DEBUG_JSON'] and reply_to)
        $stdout.puts('%s -> %s' % [ reply_to, payload ])
      end

      self.context.trap do
        self.before_request rescue nil

        handler.handle(payload, meta[:metrics], meta[:state]) do |reply_json|
          # NOTE: begin...end necessary for rescue in Ruby versions below 2.4
          begin
            if (ENV['SKEIN_DEBUG_JSON'] and reply_to)
              $stdout.puts('%s <- %s' % [ reply_to, reply_json ])
            end

            # Secondary (inner) trap required since some handlers are async
            self.context.trap do
              channel.acknowledge(delivery_tag, true)

              return unless (reply_to)

              channel.default_exchange.publish(
                reply_json,
                routing_key: reply_to,
                content_type: 'application/json'
              )

            rescue RejectMessage
              # Reject the message
              channel.reject(delivery_tag, false)
            rescue RetryMessage
              # Reject and requeue the message
              channel.reject(delivery_tag, true)
            rescue => e
              self.after_exception(e) rescue nil
              raise e
            ensure
              self.after_request rescue nil
            end
          end
        end
      end
    end
  end

  def with_channel_in_thread(recover: true, name: nil)
    meta = {
      metrics: metrics_tracker,
      state: state_tracker
    }

    @operations << meta

    meta[:thread] = Thread.new do
      Thread.abort_on_exception = true
      Thread.current.name = name

      begin
        channel = meta[:channel] = self.create_channel

        yield(channel, meta)

        channel.close rescue nil

        redo if (recover)

      ensure
        # NOTE: The `.close` call may fail for a variety of reasons, but the
        #       important thing here is an attempt is made, regardless of
        #       outcome.
        channel&.close rescue nil
      end
    end
  end

  def handler
    @handler ||= Skein::Handler.for(self)
  end
end
