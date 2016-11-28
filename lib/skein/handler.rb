class Skein::Handler
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

  def initialize(target)
    @target = target
  end

  def handle(message_json)
    # REFACTOR: Roll this into a module to keep it more contained.
    # REFACTOR: Use Skein::RPC::Request
    request =
      begin
        JSON.load(message_json)

      rescue Object => e
        @context.exception!(e, message_json)

        return yield(JSON.dump(
          result: nil,
          error: '[%s] %s' % [ e.class, e ],
          id: request['id']
        ))
      end

    case (request)
    when Hash
      # Acceptable
    else
      return yield(JSON.dump(
        result: nil,
        error: 'Request does not conform to the JSON-RPC format.',
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
        result: nil,
        error: 'Request does not conform to the JSON-RPC format, missing valid method.',
        id: request['id']
      ))
    end

    begin
      delegate(request['method'], *request['params']) do |result, error = nil|
        yield(JSON.dump(
          result: result,
          error: error,
          id: request['id']
        ))
      end
    rescue Object => e
      @reporter and @reporter.exception!(e, message_json)

      yield(JSON.dump(
        result: nil,
        error: '[%s] %s' % [ e.class, e ],
        id: request['id']
      ))
    end
  end
end

require_relative './handler/async'
require_relative './handler/threaded'
