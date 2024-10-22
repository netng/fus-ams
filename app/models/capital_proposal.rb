class CapitalProposal < ApplicationRecord
  include Trackable
  include Downcaseable

  belongs_to :capital_proposal_type
  belongs_to :capital_proposal_group
  belongs_to :site
  belongs_to :department
  belongs_to :currency


  validates :number, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :real_number, length: { maximum: 100 }
  validates :date, presence: true
  validates :description, presence: true, length: { maximum: 500 }
  validates :equiv_amount, presence: true, numericality: true
  validates :rate, presence: true, numericality: true
  validates :amount, presence: true, numericality: true
  validates :status, presence: true, length: { maximum: 100 }
  validates :budget_ref_number, presence: true, length: { maximum: 100 }
  validates :budget_amount, presence: true, numericality: true

  def self.ransackable_attributes(auth_object = nil)
    ["amount", "budget_amount", "budget_ref_number", "capital_proposal_group_id", "capital_proposal_type_id", "created_at", "created_by", "date", "department_id", "description", "equiv_amount", "id", "ip_address", "number", "rate", "real_number", "request_id", "site_id", "status", "updated_at", "user_agent"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["capital_proposal_group", "capital_proposal_type", "department", "site"]
  end

end
