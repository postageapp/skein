require 'securerandom'
require 'fiber'

class Skein::Client < Skein::Connected
  # == Properties ===========================================================

  # == Class Methods ========================================================

  def self.rpc(*args)
    new.rpc(*args)
  end

  def self.worker(*args)
    new.worker(*args)
  end

  def self.publisher(*args)
    new.publisher(*args)
  end

  def self.subscriber(*args)
    new.subscriber(*args)
  end

  # == Instance Methods =====================================================

  def initialize(config: nil, connection: nil, context: nil)
    super(config: config, connection: connection, context: context)
  end

  def rpc(exchange_name = nil, routing_key: nil, ident: nil, expiration: nil, persistent: nil, durable: nil, timeout: nil)
    Skein::Client::RPC.new(
      exchange_name,
      routing_key: routing_key,
      connection: self.connection,
      context: self.context,
      ident: ident,
      expiration: expiration,
      persistent: persistent,
      durable: durable,
      timeout: timeout
    )
  end

  def worker(queue_name, type = nil, ident: nil, durable: nil)
    (type || Skein::Client::Worker).new(
      queue_name,
      connection: self.connection,
      context: self.context,
      ident: ident,
      durable: durable
    )
  end

  def publisher(exchange_name, type: nil, durable: nil)
    Skein::Client::Publisher.new(
      exchange_name,
      type: type,
      durable: durable,
      connection: self.connection,
      context: self.context
    )
  end

  def subscriber(exchange_name, routing_key = nil)
    Skein::Client::Subscriber.new(
      exchange_name,
      routing_key,
      connection: self.connection,
      context: self.context
    )
  end
end

require_relative './client/publisher'
require_relative './client/rpc'
require_relative './client/subscriber'
require_relative './client/worker'
