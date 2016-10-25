class Skein::RPC
  class Exception < ::RuntimeError
    attr_accessor :request

    def to_error
      Skein::RPC::Error.new(
        error: '[%s] %s' % [ self.class, self.to_s ],
        id: self.request ? self.request.id : nil
      )
    end
  end

  class InvalidPayload < Exception
  end

  class InvalidMethod < Exception
  end
end

require_relative './rpc/base'
require_relative './rpc/error'
require_relative './rpc/request'
require_relative './rpc/response'
require_relative './rpc/notification'
