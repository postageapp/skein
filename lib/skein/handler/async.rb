class Skein::Handler::Async < Skein::Handler
  # == Instance Methods =====================================================

  def delegate(*args)
    @target.send(*args) do |*response|
      yield(*response)
    end
  end
end
