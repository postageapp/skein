class Skein::Handler
  # == Properties ===========================================================

  attr_reader :context

  # == Constants ============================================================

  RPC_BASE = {
    jsonrpc: '2.0'
  }.freeze

  # == Class Methods ========================================================

  def self.for(target)
    case (target.respond_to?(:async?) and target.async?)
    when true
      Skein::Handler::Async.new(target)
    else
      Skein::Handler::Threaded.new(target)
    end
  end

  # == Instance Methods =====================================================

  def initialize(target, context = nil)
    @target = target
    @context = context
  end

  def json_rpc(contents)
    JSON.dump(RPC_BASE.merge(contents))
  end

  def handle(message_json)
    request =
      begin
        JSON.load(message_json)

      rescue Object => e
        @context and @context.exception!(e, message_json)

        return yield(rpc_json(
          error: {
            code: -32700,
            message: 'Parse error'
          },
          id: nil
        ))
      end

    case (request)
    when Hash
      # Acceptable
    else
      return yield(json_rpc(
        error: {
          code: -32600,
          message: 'Request does not conform to the JSON-RPC format.'
        },
        id: nil
      ))
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
      return yield(json_rpc(
        error: {
          code: -32600,
          message: 'Request does not conform to the JSON-RPC format, missing valid method.'
        },
        id: request['id']
      ))
    end

    begin
      delegate(request['method'], *request['params']) do |result|
        case (result)
        when Exception
          yield(json_rpc(
            error: {
              code: -32603,
              message: result.to_s
            },
            id: request['id']
          ))
        else
          yield(json_rpc(
            result: result,
            id: request['id']
          ))
        end
      end

    rescue ArgumentError => e
      # REFACTOR: Make these exception catchers only trap immediate errors,
      #           not those that occur within the delegated code.
      @context and @context.exception!(e, message_json)

      yield(json_rpc(
        error: {
          code: -32602,
          message: 'Invalid params',
          data: {
            method: request['method'],
            params: request['params'],
            message: e.to_s
          }
        },
        id: request['id']
      ))
    rescue NoMethodError => e
      @context and @context.exception!(e, message_json)

      yield(json_rpc(
        error: {
          code: -32601,
          message: 'Method not found',
          data: {
            method: request['method']
          }
        },
        id: request['id']
      ))
    rescue Object => e
      @context and @context.exception!(e, message_json)

      yield(json_rpc(
        error: {
          code: -32063, 
          message: '[%s] %s' % [ e.class, e ]
        },
        id: request['id']
      ))
    end
  end
end

require_relative './handler/async'
require_relative './handler/threaded'
