class CapitalProposalType < ApplicationRecord
  has_many :capital_proposals, dependent: :restrict_with_error

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "id", "id_capital_proposal_type", "id_value", "ip_address", "name", "request_id", "updated_at", "user_agent"]
  end
end
