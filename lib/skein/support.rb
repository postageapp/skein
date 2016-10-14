require 'socket'

module Skein::Support
  # == Module Methods =======================================================

  def self.hostname
    Socket.gethostname
  end

  def self.process_name
    $0.split(/\s/).first.split('/').last.sub(/\.rb\z/, '')
  end

  def self.process_id
    Process.pid
  end

  def self.hash_format(hash, width: nil)
    hash = hash.to_h

    width ||= hash.keys.map(&:length).sort[-1].to_i + 1

    template = "%%-%ds %%s" % [ width ]

    hash.map do |pair|
      template % pair
    end
  end

  def self.symbolize_keys(hash)
    case (hash)
    when Hash
      Hash[
        hash.map do |k,v|
          [
            k.to_s.to_sym,
            case (v)
            when Hash
              symbolize_keys(v)
            when Array
              v.map { |e| symbolize_keys(e) }
            else
              v
            end
          ]
        end
      ]
    when Array
      hash.map do |h|
        symbolize_keys(h)
      end
    else
      hash
    end
  end
end
