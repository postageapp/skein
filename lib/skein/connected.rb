class Skein::Connected
  # == Properties ===========================================================

  attr_reader :context
  attr_reader :ident
  attr_reader :connection
  attr_reader :channel

  # == Instance Methods =====================================================

  def initialize(connection: nil, context: nil)
    @shared_connection = connection

    @connection = connection || Skein::RabbitMQ.connect
    @channel = @connection.create_channel

    @context = context || Skein::Context.new
    @ident = @context.ident(self)
  end

  def close
    @channel.close
    @channel = nil

    unless (@shared_connection)
      @connection.close
      @connection = nil
    end
  end
end
