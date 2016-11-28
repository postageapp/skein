class Skein::Handler::Threaded < Skein::Handler
  # == Instance Methods =====================================================

  def delegate(*args)
    yield(@target.send(*args))
  end
end
