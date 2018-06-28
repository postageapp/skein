class Skein::TimeoutQueue
  # == Constants ============================================================

  # == Properties ===========================================================

  # == Extensions ===========================================================

  # == Relationships ========================================================

  # == Validations ==========================================================

  # == Callbacks ============================================================

  # == Scopes ===============================================================

  # == Class Methods ========================================================

  # == Instance Methods =====================================================

  def initialize
    @elems = []
    @mutex = Mutext.new
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

      raise ThreadError, 'queue empty' if @elems.empty?
      @elems.shift
    end
  end
end
