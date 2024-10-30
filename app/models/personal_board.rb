class PersonalBoard < ApplicationRecord
  has_many :purchase_orders, foreign_key: :approved_by_id, dependent: :restrict_with_error

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "id", "id_personal_board", "ip_address", "request_id", "updated_at", "user_agent", "username"]
  end
end
