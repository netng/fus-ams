class FunctionAccess < ApplicationRecord
  include Trackable

  has_many :role_function_accesses
  has_many :roles, through: :role_function_accesses, dependent: :restrict_with_error
  has_many :route_paths, dependent: :restrict_with_error

  validates :code, format: { with: /\A[A-Z0-9_]+\z/, message: I18n.t("custom.errors.invalid_code_format") }, presence: true, uniqueness: { case_sensitive: false }
end
