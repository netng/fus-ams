class ActiveRecord::Base
  # find_each_with_order untuk Rails terbaru
  def self.find_each_with_order(order:, limit: 1000, &block)
    raise ArgumentError, "Offset is not supported for find_each_with_order" if order.blank?

    page = 1

    loop do
      offset = (page - 1) * limit
      records = self.order(order).limit(limit).offset(offset)

      break if records.empty?

      records.each(&block)
      page += 1
    end
  end
end
