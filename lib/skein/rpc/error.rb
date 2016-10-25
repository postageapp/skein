class Skein::RPC::Error < Skein::RPC::Base
  # == Properties ===========================================================

  attr_accessor :error

  # == Instance Methods =====================================================

  def initialize(content = nil)
    case (content)
    when String
      self.error = content
    when Hash
      self.assign_from_hash!(content)
    when nil
      # Defaults
    else
      raise Skein::RPC::Exception, 'Invalid type: %s' % content.class
    end
  end

  def self.to_h
    {
      result: nil,
      error: self.error,
      id: self.id
    }
  end

protected
  def assign_from_hash!(hash)
    self.error = hash[:error]
    self.id = hash[:id]
  end
end
