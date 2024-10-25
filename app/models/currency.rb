class Currency < ApplicationRecord
  include Trackable
  
  has_many :capital_proposals, dependent: :restrict_with_error
  has_many :purchase_orders, dependent: :restrict_with_error
end
