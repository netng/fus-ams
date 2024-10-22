class CapitalProposalGroup < ApplicationRecord
  belongs_to :capital_proposal_group_header

  has_many :capital_proposals, dependent: :restrict_with_error


  def self.ransackable_attributes(auth_object = nil)
    ["capital_proposal_group_header_id", "created_at", "created_by", "id", "id_capital_proposal_group", "id_value", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end
end
