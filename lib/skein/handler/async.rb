class Skein::Handler::Async < Skein::Handler
  # == Instance Methods =====================================================

  def delegate(*args)
    fiber = Fiber.new do
      @target.send(*args) do |*response|
        Fiber.yield(*response)
      end
    end

    yield(fiber.resume)
  end
end
