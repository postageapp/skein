module Skein::Adapter
  # == Mixin Methods =========================================================
  
  def subscribe(queue, block: true, manual_ack: true)
    p queue

    case (queue.class.to_s.split(/::/)[0])
    when 'Bunny'
      queue.subscribe(block: block, manual_ack: manual_ack) do |delivery_info, properties, payload|
        yield(payload, delivery_info[:delivery_tag], properties[:reply_to])
      end
    when 'MarchHare'
      queue.subscribe(block: block, manual_ack: manual_ack) do |metadata, payload|
        yield(payload, metadata.delivery_tag, metadata.reply_to)
      end
    end
  end

  extend self
end
