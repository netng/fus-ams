class RequestForPurchase < ApplicationRecord
  include Trackable
  include Downcaseable

  belongs_to :capital_proposal, optional: true
  belongs_to :from_department, class_name: "Department"
  belongs_to :to_department, class_name: "Department"

  has_many :request_for_purchase_details, inverse_of: :request_for_purchase, dependent: :restrict_with_error
  accepts_nested_attributes_for :request_for_purchase_details

  validates :number, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :date, presence: true
  validates :material_code, presence: true, length: { maximum: 100 }
  validates :remarks, length: { maximum: 100 }
  validates :issued_by, length: { maximum: 100 }
  validates :authorized_by, length: { maximum: 100 }
  validates :status, presence: true, length: { maximum: 100 }

  def self.ransackable_attributes(auth_object = nil)
    ["authorized_by", "capital_proposal_id", "created_at", "created_by", "date", "from_department_id", "id", "ip_address", "issued_by", "material_code", "number", "remarks", "request_id", "status", "to_department_id", "updated_at", "user_agent"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["capital_proposal", "from_department", "to_department"]
  end

end
