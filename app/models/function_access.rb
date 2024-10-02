class FunctionAccess < ApplicationRecord
  include Trackable

  validates :code, format: { with: /\A[\w]+\z/, message: I18n.t("custom.errors.invalid_code_format") }, presence: true, uniqueness: true
end
