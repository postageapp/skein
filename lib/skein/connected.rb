class Skein::Connected
  # == Properties ===========================================================

  attr_reader :context
  attr_reader :ident
  attr_reader :connection

  # == Instance Methods =====================================================

  def initialize(connection: nil, context: nil)
    @mutex = Mutex.new
    @shared_connection = !!connection

    @connection = connection || Skein::RabbitMQ.connect
    @channels = [ ]

    @context = context || Skein::Context.new
    @ident = @context.ident(self)
  end

  def lock
    @mutex.synchronize do
      yield
    end
  end

  def create_channel
    channel = @connection.create_channel

    if (channel.respond_to?(:prefetch=))
      channel.prefetch = 1
    else
      channel.prefetch(1)
    end

    @channels << channel

    channel
  end

  def channel
    @channel ||= self.create_channel
  end

  def close
    lock do
      begin
        @channels.each do |channel|
          channel.open? and channel.close
        end

      rescue => e
        if (defined?(MarchHare))
          case (e)
          when MarchHare::ChannelLevelException, MarchHare::ChannelAlreadyClosed
            # Ignored since we're finished with the channel anyway
          else
            raise e
          end
        else
          raise e
        end
      end

      @channel = nil
      @channels.clear
      
      unless (@shared_connection)
        @connection and @connection.close
        @connection = nil
      end
    end
  end
end
