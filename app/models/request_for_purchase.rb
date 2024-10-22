class RequestForPurchase < ApplicationRecord
  include Trackable
  include Downcaseable

  belongs_to :capital_proposal, optional: true
  belongs_to :from_department, class_name: "Department"
  belongs_to :to_department, class_name: "Department"

  validates :number, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :date, presence: true
  validates :material_code, presence: true, length: { maximum: 100 }
  validates :remarks, length: { maximum: 100 }
  validates :issued_by, length: { maximum: 100 }
  validates :authorized_by, length: { maximum: 100 }
  validates :status, presence: true, length: { maximum: 100 }


end
