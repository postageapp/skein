class Skein::RPC::Response < Skein::RPC::Base
  # == Properties ===========================================================

  attr_accessor :result
  attr_accessor :error

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

protected
  def assign_from_hash!(hash)
    self.result = hash[:result]
    self.error = hash[:error]
    self.id = hash[:id]
  end
end
