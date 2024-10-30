class DeliveryOrder < ApplicationRecord
  include Trackable
  
  belongs_to :purchase_order, optional: true

  validates :number, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :date, presence: true
  validates :description, length: { maximum: 500 }


  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "date", "description", "id", "ip_address", "number", "purchase_order_id", "request_id", "updated_at", "user_agent", "warranty_expired"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["purchase_order"]
  end
end
