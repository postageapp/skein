class Skein::RPC::Request < Skein::RPC::Base
  # == Properties ===========================================================

  attr_accessor :method
  attr_accessor :params

  # == Instance Methods =====================================================

  def initialize(content = nil)
    case (content)
    when String
      data = Skein::Support.symbolize_keys(JSON.load(content))

      assign_from_hash!(data)
    when Hash
      assign_from_hash!(content)
    when nil
      self.id = SecureRandom.uuid
    else
      raise Skein::RPC::InvalidPayload, 'Invalid payload type: %s' % content.class
    end
  end

  def to_h
    {
      method: self.method,
      params: self.params,
      id: self.id
    }
  end

  def response(result: nil, error: nil)
    if (result)
      Skein::RPC::Response.new(
        result: result,
        id: self.id
      )
    elsif (error)
      Skein::RPC::Error.new(
        error: error,
        id: self.id
      )
    end
  end

protected
  def assign_from_hash!(hash)
    self.method = hash[:method]
    self.params = Skein::Support.arrayify(hash[:params])
    self.id = hash[:id]

    case (self.method)
    when String
      unless (self.method.match(/\A\w+\z/))
        e = Skein::RPC::InvalidMethod.new('%s is not a valid RPC method name.' % self.method.inspect)
        e.request = self

        raise e
      end
    end
  end
end
