class Skein::Context
  # == Properties ===========================================================

  attr_reader :hostname
  attr_reader :process_name
  attr_reader :process_id
  attr_accessor :reporter

  # == Class Methods ========================================================

  def self.default
    @default ||= self.new
  end

  # == Instance Methods =====================================================

  def initialize(hostname: nil, process_name: nil, process_id: nil, config: nil)
    @hostname = (hostname || Skein::Support.hostname).dup.freeze
    @process_name = (process_name || Skein::Support.process_name).dup.freeze
    @process_id = process_id || Skein::Support.process_id
  end

  def ident(object)
    # FUTURE: Add pack/unpack methods for whatever format this ends up being
    #         so the components can be extracted by another application for
    #         diagnostic reasons.
    '%s#%d+%s@%s' % [
      @process_name,
      @process_id,
      object.object_id,
      @hostname
    ]
  end

  def exception!(*args)
    @reporter and @reporter.exception!(*args)
  end

  def trap
    yield
  rescue SystemExit
    raise
  rescue Object => e
    self.exception!(e)
  end
end
