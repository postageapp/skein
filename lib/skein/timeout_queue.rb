class Skein::TimeoutQueue
  # == Instance Methods =====================================================

  def initialize
    @elems = []
    @mutex = Mutex.new
    @cond_var = ConditionVariable.new
  end

  def <<(elem)
    @mutex.synchronize do
      @elems << elem
      @cond_var.signal
    end
  end

  def pop(blocking = true, timeout = nil)
    @mutex.synchronize do
      if (blocking)
        if (timeout.nil?)
          while (@elems.empty?)
            @cond_var.wait(@mutex)
          end
        else
          timeout_time = Time.now.to_f + timeout
          while (@elems.empty? && (remaining_time = timeout_time - Time.now.to_f) > 0 )
            @cond_var.wait(@mutex, remaining_time)
          end
        end
      end

      if (@elems.empty?)
        raise ThreadError, 'Queue Empty: Time Out'
      end

      @elems.shift
    end
  end
end
