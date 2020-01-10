require 'json'

module Skein
  # == Constants ============================================================

  VERSION = File.read(File.expand_path('../VERSION', __dir__)).chomp.freeze

  # == Exceptions ===========================================================

  class Exception < ::StandardError
  end

  class TimeoutException < Exception
  end

  # == Module Methods =======================================================

  def self.version
    VERSION
  end

  def self.config=(config)
    @config = config
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
require_relative './skein/support'
require_relative './skein/timeout_queue'
