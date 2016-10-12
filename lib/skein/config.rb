require 'ostruct'
require 'yaml'

class Skein::Config < OpenStruct
  # == Constants ============================================================

  RAILS_ENV_DEFAULT = 'development'.freeze

  DRIVERS = {
    bunny: 'Bunny',
    march_hare: 'MarchHare'
  }.freeze

  DRIVER_DEFAULT = (
    DRIVERS.find do |name, const|
      const_defined?(const)
    end || [ ]
  )[0] || :bunny

  DEFAULTS = {
    host: '127.0.0.1',
    port: 5672,
    username: 'guest',
    password: 'guest',
    driver: DRIVER_DEFAULT
  }.freeze

  # == Instance Methods =====================================================

  def initialize(options = nil)
    path_prefix = Dir.pwd
    env = ENV['RAILS_ENV'] || RAILS_ENV_DEFAULT

    if (defined?(Rails))
      path_prefix = Rails.root
      env = Rails.env
    end

    config_path = File.expand_path('config/skein.yml', path_prefix)

    case (options)
    when String
      if (File.exist?(options))
        config_path = options
      end
    when Hash
      super(options)

      return
    end

    if (File.exists?(config_path))
      super(DEFAULTS.merge(YAML.load_file(config_path)[env] || { }))
    else
      super(DEFAULTS)
    end
  end
end
