class Skein::Handler::Async < Skein::Handler
  # == Instance Methods =====================================================

  def delegate(*args)
    @target.send(*args) do |*response|
      # FIX: Capture errors at this level during yield
      yield(*response)
    end
  end
end
