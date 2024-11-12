class DeliveryOrder < ApplicationRecord
  include Trackable
  
  belongs_to :purchase_order, optional: true
  has_many :assets, dependent: :restrict_with_error

  before_validation :strip_do_number

  validates :number, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :date, presence: true
  validates :description, length: { maximum: 500 }


  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "date", "description", "id", "ip_address", "number", "purchase_order_id", "request_id", "updated_at", "user_agent", "warranty_expired"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["purchase_order"]
  end

  private
    def strip_do_number
      if number.present?
        self.number = number.strip
      end
    end
end
