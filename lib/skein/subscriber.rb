class Skein::Subscriber
  # == Constants ============================================================

  OPTIONS_DEFAULT = {
    manual_ack: true,
    block: true,
    headers: true
  }.freeze

  # == Instance Methods =====================================================

  def initialize(queue, options = nil)
    options = OPTIONS_DEFAULT.merge(options || { })

    @thread = Thread.new do
      Thread.abort_on_exception = true

      case (queue.class.to_s)
      when 'Bunny::Queue'
        queue.subscribe(options) do |delivery_info, properties, payload|
          yield(payload, delivery_info[:delivery_tag], properties[:reply_to])
        end
      when 'MarchHare::Queue'
        queue.subscribe(options) do |metadata, payload|
          yield(payload, metadata.delivery_tag, metadata.reply_to)
        end
      else
        raise "Unsupported RabbitMQ Queue: #{queue.class.inspect}"
      end
    end
  end

  def kill
    @thread and @thread.kill
  end

  def join
    @thread and @thread.join
  end
end
