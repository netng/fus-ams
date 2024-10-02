class AccountRole < ApplicationRecord
  include Trackable
  
  belongs_to :account
  belongs_to :role
end
