require 'securerandom'
require 'fiber'

class Skein::Client < Skein::Connected
  # == Properties ===========================================================

  # == Class Methods ========================================================

  def self.rpc(*args)
    new.rpc(*args)
  end

  def self.receiver(*args)
    new.receiver(*args)
  end

  def self.publisher(*args)
    new.publisher(*args)
  end

  def self.subscriber(*args)
    new.subscriber(*args)
  end

  # == Instance Methods =====================================================

  def initialize(connection: nil, context: nil)
    super(connection: connection, context: context)
  end

  def rpc(queue_name = nil)
    Skein::Client::RPC.new(queue_name, connection: self.connection, context: self.context)
  end

  def receiver
    Skein::Client::Receiver.new(connection: self.connection, context: self.context)
  end

  def publisher(queue_name)
    Skein::Client::Publisher.new(queue_name, connection: self.connection, context: self.context)
  end

  def subscriber(queue_name, routing_key = nil)
    Skein::Client::Subscriber.new(queue_name, routing_key, connection: self.connection, context: self.context)
  end
end

require_relative './client/publisher'
require_relative './client/rpc'
require_relative './client/subscriber'
require_relative './client/worker'
