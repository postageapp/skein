class Skein::TimeoutQueue
  # == Instance Methods =====================================================

  def initialize(blocking: true, timeout: nil)
    @response = [ ]
    @blocking = blocking
    @timeout = timeout&.to_f
    @mutex = Mutex.new
    @cond_var = ConditionVariable.new
  end

  def <<(result)
    @mutex.synchronize do
      @response << result

      @cond_var.signal
    end
  end

  def pop
    @mutex.synchronize do
      if (@blocking)
        if (@timeout)
          timeout_time = Time.now.to_f + @timeout

          while (@response.empty? and (remaining_time = timeout_time - Time.now.to_f) > 0)
            @cond_var.wait(@mutex, remaining_time)
          end
        else
          while (@response.empty?)
            @cond_var.wait(@mutex)
          end
        end
      end

      if (@response.empty?)
        raise Skein::TimeoutException, 'Queue Empty: Time Out'
      end

      @response.shift
    end
  end
end
