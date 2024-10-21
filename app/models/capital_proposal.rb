class CapitalProposal < ApplicationRecord
  belongs_to :capital_proposal_type
  belongs_to :capital_proposal_group
  belongs_to :site
  belongs_to :department
end
