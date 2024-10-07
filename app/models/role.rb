class Role < ApplicationRecord
  include Trackable
  include Downcaseable

  has_many :accounts, dependent: :restrict_with_error

  has_many :role_function_accesses
  has_many :function_accesses, through: :role_function_accesses, dependent: :restrict_with_error

  downcase_fields :name
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
end
