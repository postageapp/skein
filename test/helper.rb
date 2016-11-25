require 'test/unit'

$LOAD_PATH << File.expand_path('../lib', File.dirname(__FILE__))

require 'skein'

# Simulate Rails 'test' environment
ENV['RAILS_ENV'] = 'test'

# Ensure tests are run from the root of the project so that configuration
# files can be found and loaded.
Dir.chdir(File.expand_path('../', File.dirname(__FILE__)))

class Test::Unit::TestCase
  def assert_mapping(map)
    result_map = map.each_with_object({ }) do |(k,v), h|
      h[k] = yield(k)
    end
    
    assert_equal map, result_map do
      result_map.each_with_object([ ]) do |(k,v), a|
        unless (v == map[k])
          a << k
        end
      end.map do |s|
        "Input: #{s.inspect}\n  Expected: #{map[s].inspect}\n  Result:   #{result_map[s].inspect}\n"
      end.join
    end
  end

  def assert_no_threads(message = nil)
    threads = Thread.list.length

    yield

    assert_equal threads, Thread.list.length, message
  end

  def data_path(name)
    File.expand_path(File.join('data', name), File.dirname(__FILE__))
  end
end
