module Skein::RabbitMQ
  # == Exceptions ===========================================================

  class MissingDriver < RuntimeError
  end

  # == Module Methods =======================================================

  def self.force_require!(config = nil)
    config ||= Skein.config

    case (config.driver.to_s)
    when 'bunny', 'rubybunny'
      unless (defined?(Bunny))
        require 'bunny'
      end
    when 'march_hare', 'marchhare'
      unless (defined?(MarchHare))
        require 'march_hare'
      end
    else
      raise MissingDriver, 'Missing or invalid configuration for: driver'
    end
  end

  # REFACTOR: These should be moved to an abstract adapter
  def self.connect(config = nil)
    config ||= Skein.config

    self.force_require!(config)

    case (config.driver.to_s)
    when 'bunny', 'rubybunny'
      bunny = Bunny.new(config.to_h)

      bunny.start

      bunny
    when 'march_hare', 'marchhare'
      MarchHare.connect(config.to_h)
    else
      raise MissingDriver, 'Missing or invalid configuration for: driver'
    end
  end
end
