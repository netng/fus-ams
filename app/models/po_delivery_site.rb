class PoDeliverySite < ApplicationRecord

  has_many :purchase_orders, dependent: :restrict_with_error

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "id", "id_po_delivery_site", "id_value", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end

end
