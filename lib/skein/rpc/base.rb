require 'json'

class Skein::RPC::Base
  # == Exceptions ===========================================================

  # == Properties ===========================================================
  
  attr_accessor :id

  # == Instance Methods =====================================================

  def to_h
    {
      id: self.id
    }
  end

  def to_json
    JSON.dump(
      self.to_h
    )
  end
end
