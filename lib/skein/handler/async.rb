class Skein::Handler::Async < Skein::Handler
  # == Instance Methods =====================================================

  def delegate(*args)
    thread = Thread.current

    @target.send(*args) do |response, error|
      if (thread == Thread.current)
        thread = nil
      else
        thread.wakeup
      end

      yield(response, error)
    end

    thread and thread.stop
  end
end
