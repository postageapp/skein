require 'securerandom'
require 'fiber'

class Skein::Client::RPC < Skein::Connected
  # == Exceptions ===========================================================

  class RPCException < Exception
  end

  # == Constants ============================================================

  EXCHANGE_NAME_DEFAULT = ''.freeze

  # == Properties ===========================================================

  # == Instance Methods =====================================================

  def initialize(exchange_name = nil, routing_key: nil, connection: nil, context: nil, ident: nil, expiration: nil, persistent: true, durable: true, timeout: nil)
    super(connection: connection, context: context, ident: ident)

    @routing_key = routing_key
    @timeout = timeout

    @rpc_exchange = self.channel.direct(
      exchange_name || EXCHANGE_NAME_DEFAULT,
      durable: durable
    )

    @response_queue = self.channel.queue(
      @ident,
      durable: false,
      header: true,
      auto_delete: true
    )
    @expiration = expiration
    @persistent = !!persistent

    @callback = { }

    @consumer = Skein::Adapter.subscribe(@response_queue, block: false) do |payload, delivery_tag, reply_to|
      self.context.trap do
        if (ENV['SKEIN_DEBUG_JSON'])
          $stdout.puts(payload)
        end

        response = JSON.load(payload)

        if (callback = @callback.delete(response['id']))
          if (response['error'])
            exception =
              case (response['error'] and response['error']['code'])
              when -32601
                NoMethodError.new(
                  "%s from `%s' RPC call" % [
                    response.dig('error', 'message'),
                    response.dig('error', 'data', 'method')
                  ]
                )
              when -32602
                ArgumentError.new(
                  response.dig('error', 'data', 'message') || 'wrong number of arguments'
                )
              else
                RPCException.new(
                  response.dig('error', 'data', 'message') || response.dig('error', 'message')
                )
              end

            case (callback)
            when Skein::TimeoutQueue
              callback << exception
            when Proc
              callback.call(exception)
            end
          else
            case (callback)
            when Skein::TimeoutQueue
              callback << response['result']
            when Proc
              callback.call(response['result'])
            end
          end
        end

        self.channel.acknowledge(delivery_tag)
      end
    end
  end

  # Temporarily deliver RPC calls to a different routing key. The supplied
  # block is executed with this temporary routing in effect.
  def reroute!(routing_key)
    routing_key, @routing_key = @routing_key, routing_key

    yield if (block_given?)

    @routing_key = routing_key
  end

  def close
    @consumer&.cancel
    @consumer = nil

    super
  end

  def method_missing(name, *args, &block)
    name = name.to_s

    blocking = !name.sub!(/!\z/, '')

    message_id = SecureRandom.uuid
    request = JSON.dump(
      jsonrpc: '2.0',
      method: name,
      params: args,
      id: message_id
    )

    @rpc_exchange.publish(
      request,
      routing_key: @routing_key,
      reply_to: blocking ? @ident : nil,
      content_type: 'application/json',
      message_id: message_id,
      persistent: @persistent,
      expiration: @expiration
    )

    if (block_given?)
      @callback[message_id] =
        if (defined?(EventMachine))
          EventMachine.next_tick(&block)
        else
          block
        end
    elsif (blocking)
      queue = Skein::TimeoutQueue.new(blocking: true, timeout: @timeout)

      @callback[message_id] = queue

      case (result = queue.pop)
      when Exception
        raise result
      else
        result
      end
    end
  end
end
