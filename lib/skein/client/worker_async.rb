require 'json'

class Skein::Client::WorkerAsync < Skein::Connected
  # == Properties ===========================================================

  attr_reader :thread

  # == Instance Methods =====================================================

  def initialize(queue_name, connection: nil, context: nil)
    super(connection: connection, context: context)

    lock do
      queue = self.channel.queue(queue_name, durable: true)

      @thread = Thread.new do
        Thread.abort_on_exception = true

        queue.subscribe(manual_ack: true, block: true, headers: true) do |metadata, payload, extra|
          # FIX: Clean up friction here between Bunny and March Hare
          # puts [metadata,payload,extra].map(&:class).inspect

          reply_to = nil
          headers = nil

          # NOTE: Bunny and MarchHare deal with this in a slightly different
          #       capcity where the reply_to header is moved around.
          if (extra)
            headers = payload
            payload = extra

            reply_to = headers[:reply_to]
          else
            reply_to = metadata.reply_to
          end

          handle(payload) do |reply|
            channel.acknowledge(metadata.delivery_tag, true)

            if (reply_to)
              channel.default_exchange.publish(
                reply,
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

protected
  def handle(message_json)
    # REFACTOR: Roll this into a module to keep it more contained.
    # REFACTOR: Use Skein::RPC::Request
    request =
      begin
        JSON.load(message_json)

      rescue Object => e
        @context.exception!(e, message_json)

        return JSON.dump(
          result: nil,
          error: '[%s] %s' % [ e.class, e ],
          id: request['id']
        )
      end

    case (request)
    when Hash
      # Acceptable
    else
      return JSON.dump(
        result: nil,
        error: 'Request does not conform to the JSON-RPC format.',
        id: nil
      )
    end

    request['params'] =
      case (params = request['params'])
      when Array
        params
      when nil
        request.key?('params') ? [ nil ] : [ ]
      else
        [ request['params'] ]
      end

    unless (request['method'] and request['method'].is_a?(String) and request['method'].match(/\S/))
      return JSON.dump(
        result: nil,
        error: 'Request does not conform to the JSON-RPC format, missing valid method.',
        id: request['id']
      )
    end

    begin
      send(request['method'], *request['params']) do |result|
        yield(
          JSON.dump(
            result: result,
            error: nil,
            id: request['id']
          )
        )
      end
    rescue Object => e
      @reporter and @reporter.exception!(e, message_json)

      JSON.dump(
        result: nil,
        error: '[%s] %s' % [ e.class, e ],
        id: request['id']
      )
    end
  end
end
