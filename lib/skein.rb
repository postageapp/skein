require 'json'

module Skein
  VERSION = File.read(File.expand_path('../VERSION', File.dirname(__FILE__))).chomp.freeze

  def self.version
    VERSION
  end

  def self.config
    @config ||= Skein::Config.new
  end
end

require_relative './skein/connected'

require_relative './skein/adapter'
require_relative './skein/client'
require_relative './skein/config'
require_relative './skein/context'
require_relative './skein/handler'
require_relative './skein/rabbitmq'
require_relative './skein/reporter'
require_relative './skein/rpc'
require_relative './skein/support'
