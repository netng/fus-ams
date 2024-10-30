class RequestForPurchaseDetail < ApplicationRecord
  belongs_to :currency, optional: true
  belongs_to :request_for_purchase, optional: true
  belongs_to :purchase_order, optional: true


  validates :qty, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :rate, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price, presence: true, numericality: { only_integer: true }

  def check_po_presence
    if purchase_order.present?
      errors.add(:base, "Failed to delete purchase order details because dependent exist on purchase order")
      throw(:abort)
    end
  end

end
