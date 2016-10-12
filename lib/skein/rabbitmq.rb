module Skein::RabbitMQ
  # == Exceptions ===========================================================

  class MissingDriver < RuntimeError
  end

  # == Module Methods =======================================================

  def self.connect(config = nil)
    config ||= Skein.config

    case (config.driver.to_s)
    when 'bunny', 'rubybunny'
      unless (defined?(Bunny))
        require 'bunny'
      end

      rmq = Bunny.new(config.to_h)

      rmq.start

      rmq
    when 'march_hare', 'marchhare'
      unless (defined?(MarchHare))
        require 'march_hare'
      end

      MarchHare.connect(config.to_h)
    else
      raise MissingDriver, 'Missing or invalid configuration for: driver'
    end
  end
end
