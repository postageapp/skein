class Skein::Connected
  # == Properties ===========================================================

  attr_reader :context
  attr_reader :ident
  attr_reader :connection

  # == Instance Methods =====================================================

  def initialize(config: nil, connection: nil, context: nil, ident: nil)
    @mutex = Mutex.new

    @config = config
    @connection_shared = !connection
    @connection = connection

    self.connect
    @channels = [ ]

    @context = context || Skein::Context.new
    @ident = ident || @context.ident(self)
  end

  def connection_shared?
    @connection_shared
  end

  def lock
    @mutex.synchronize do
      yield
    end
  end

  def repeat_until_not_nil(delay: 1.0)
    r = nil

    loop do
      r = yield

      break if r

      sleep(delay)
    end

    r
  end

  def connect
    @connection ||= repeat_until_not_nil do
      @connection_shared = false
      Skein::RabbitMQ.connect(@config)
    end
  end

  def reconnect
    @connection = nil

    self.connect
  end

  def create_channel(auto_retry: false)
    channel = begin
      @connection.create_channel

    rescue RuntimeError
      sleep(1)

      self.reconnect

      retry
    end

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
      @channels.each do |channel|
        begin
          channel.close

        rescue => e
          if (defined?(MarchHare))
            case (e)
            when MarchHare::ChannelLevelException, MarchHare::ChannelAlreadyClosed
              # Ignored since we're finished with the channel anyway
            else
              raise e
            end
          elsif (defined?(Bunny))
            case (e)
            when Bunny::ChannelAlreadyClosed
              # Ignored since we're finished with the channel anyway
            else
              raise e
            end
          else
            raise e
          end
        end
      end

      @channels = [ ]

      unless (@connection_shared)
        @connection&.close
        @connection = nil
      end
    end
  end
end
