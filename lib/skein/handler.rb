class Skein::Handler
  # == Properties ===========================================================

  attr_reader :context

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

  def handle(message_json)
    request =
      begin
        JSON.load(message_json)

      rescue Object => e
        @context and @context.exception!(e, message_json)

        return yield(JSON.dump(
          result: nil,
          error: '[%s] %s' % [ e.class, e ],
          id: nil
        ))
      end

    case (request)
    when Hash
      # Acceptable
    else
      return yield(JSON.dump(
        jsonrpc: '2.0',
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
      return yield(JSON.dump(
        jsonrpc: '2.0',
        error: {
          code: -32600,
          message: 'Request does not conform to the JSON-RPC format, missing valid method.'
        },
        id: request['id']
      ))
    end

    begin
      delegate(request['method'], *request['params']) do |result, error = nil|
        yield(JSON.dump(
          jsonrpc: '2.0',
          result: result,
          error: error,
          id: request['id']
        ))
      end
    rescue NoMethodError
      @context and @context.exception!(e, message_json)

      yield(JSON.dump(
        jsonrpc: '2.0',
        error: {
          code: -32601,
          message: 'Method not found'
        },
        id: request['id']
      ))
    rescue Object => e
      @context and @context.exception!(e, message_json)

      yield(JSON.dump(
        jsonrpc: '2.0',
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
