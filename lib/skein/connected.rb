class Skein::Connected
  # == Properties ===========================================================

  attr_reader :context
  attr_reader :ident
  attr_reader :connection
  attr_reader :channel

  # == Instance Methods =====================================================

  def initialize
    @context = Skein::Context.new
    @ident = @context.ident(self)

    @connection = Skein::RabbitMQ.connect
    @channel = @connection.channel
  end

  def close
    @channel.close
    @channel = nil

    @connection.close
    @connection = nil
  end
end
