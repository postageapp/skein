require 'ostruct'
require 'yaml'

class Skein::Config < OpenStruct
  # == Constants ============================================================

  CONFIG_PATH_DEFAULT = 'config/skein.yml'.freeze

  ENV_DEFAULT = 'development'.freeze

  DRIVERS = {
    bunny: 'Bunny',
    march_hare: 'MarchHare'
  }.freeze

  DRIVER_PLATFORM_DEFAULT = Hash.new(:bunny).merge(
    "java" => :march_hare
  ).freeze

  DRIVER_DEFAULT = (
    DRIVERS.find do |name, const|
      const_defined?(const)
    end || [ ]
  )[0] || DRIVER_PLATFORM_DEFAULT[RUBY_PLATFORM]

  DEFAULTS = {
    host: '127.0.0.1',
    port: 5672,
    username: 'guest',
    password: 'guest',
    driver: DRIVER_DEFAULT,
    namespace: nil
  }.freeze

  # == Class Methods ========================================================

  def self.root
    if (defined?(Rails))
      Rails.root
    else
      Dir.pwd
    end
  end

  def self.env
    if (defined?(Rails))
      Rails.env.to_s
    else
      ENV['RAILS_ENV'] || ENV_DEFAULT
    end
  end

  def self.path
    File.expand_path(CONFIG_PATH_DEFAULT, self.root)
  end

  def self.exist?
    File.exist?(self.path)
  end

  # == Instance Methods =====================================================

  def initialize(options = nil)
    config_path = nil

    case (options)
    when String
      if (File.exist?(options))
        config_path = options
      end
    when Hash
      super(
        DEFAULTS.merge(
          Hash[
            options.map do |k, v|
              [ k.nil? ? nil : k.to_sym, v ]
            end
          ]
        )
      )

      return
    when false, :default
      # Ignore configuration file, use defaults
    else
      config_path = File.expand_path('config/skein.yml', self.class.root)
    end

    if (config_path and File.exist?(config_path))
      super(DEFAULTS.merge(
        YAML.load_file(config_path, aliases: true)[self.class.env] || { }
      ))
    else
      super(DEFAULTS)
    end
  end
end
