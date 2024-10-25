class PurchaseOrder < ApplicationRecord
  include Trackable
  include Downcaseable

  belongs_to :vendor
  belongs_to :request_for_purchase
  belongs_to :ship_to_site, class_name: "Site"
  belongs_to :currency
  belongs_to :approved_by, class_name: "PersonalBoard"

  has_many :request_for_purchase_details, dependent: :restrict_with_error
  accepts_nested_attributes_for :request_for_purchase_details, reject_if: :all_blank

  validates :number, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :date, presence: true
  validates :delivery_date, presence: true
  validates :payment_remarks, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :status, presence: true, length: { maximum: 500 }

  def self.ransackable_attributes(auth_object = nil)
    ["amount_by_currency", "amount_by_rate", "approved_by_id", "created_at", "created_by", "currency_id", "date", "delivery_date", "description", "id", "ip_address", "number", "payment_remarks", "rate", "request_for_purchase_id", "request_id", "ship_to_site_id", "status", "updated_at", "user_agent", "vendor_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["approved_by", "currency", "request_for_purchase", "ship_to_site", "vendor"]
  end

end
