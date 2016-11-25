class Skein::Connected
  # == Properties ===========================================================

  attr_reader :context
  attr_reader :ident
  attr_reader :connection
  attr_reader :channel

  # == Instance Methods =====================================================

  def initialize(connection: nil, context: nil)
    @mutex = Mutex.new
    @shared_connection = !!connection

    @connection = connection || Skein::RabbitMQ.connect
    @channel = @connection.create_channel

    @context = context || Skein::Context.new
    @ident = @context.ident(self)
  end

  def lock
    @mutex.synchronize do
      yield
    end
  end

  def close
    lock do
      begin
        @channel and @channel.close

      rescue => e
        if (defined?(MarchHare))
          case e
          when MarchHare::ChannelLevelException, MarchHare::ChannelAlreadyClosed
            # Ignored since we're finished with the channel anyway
          else
            raise e
          end
        end
      end

      @channel = nil

      unless (@shared_connection)
        @connection and @connection.close
        @connection = nil
      end
    end
  end
end
