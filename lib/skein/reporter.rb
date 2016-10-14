class Skein::Reporter
  # == Instance Methods =====================================================
  
  def initialize
    @logger = Birling.new
  end

  def exception!(e, *meta)
    # ...
  end
end
