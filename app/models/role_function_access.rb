class RoleFunctionAccess < ApplicationRecord
  include Trackable

  belongs_to :role
  belongs_to :function_access
end
