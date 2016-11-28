class Skein::Handler::Async < Skein::Handler
  # == Instance Methods =====================================================

  def delegate(*args)
    @target.send(*args) do |response, error|
      yield(response, error)
    end
  end
end
