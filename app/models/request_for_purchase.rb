class RequestForPurchase < ApplicationRecord
  include Trackable
  include Downcaseable

  belongs_to :capital_proposal, optional: true
  belongs_to :from_department, class_name: "Department"
  belongs_to :to_department, class_name: "Department"

  has_many :request_for_purchase_details, inverse_of: :request_for_purchase, dependent: :destroy
  accepts_nested_attributes_for :request_for_purchase_details, allow_destroy: true, reject_if: :all_blank

  has_many :purchase_orders, dependent: :restrict_with_error

  validates :number, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :date, presence: true
  validates :material_code, presence: true, length: { maximum: 100 }
  validates :remarks, length: { maximum: 100 }
  validates :issued_by, length: { maximum: 100 }
  validates :authorized_by, length: { maximum: 100 }
  validates :status, presence: true, length: { maximum: 100 }


  before_save :set_sub_total

  def self.ransackable_attributes(auth_object = nil)
    ["authorized_by", "capital_proposal_id", "created_at", "created_by", "date", "from_department_id", "id", "ip_address", "issued_by", "material_code", "number", "remarks", "request_id", "status", "to_department_id", "updated_at", "user_agent"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["capital_proposal", "from_department", "to_department"]
  end

  private
  def set_sub_total
    self.request_for_purchase_details.each do |rfp_detail|
      rfp_detail.sub_total = rfp_detail.qty * rfp_detail.price * rfp_detail.rate
    end
  end

end
