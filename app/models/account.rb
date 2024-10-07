class Account < ApplicationRecord
  include Trackable
  include Downcaseable

  has_secure_password

  belongs_to :role

  downcase_fields :email
  downcase_fields :username

  validates :username, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-zA-Z0-9\-.]+\z/, message: I18n.t("custom.errors.invalid_username_format") }
  
  validates :password, length: { minimum: 3 }, unless: -> { password.blank? }

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true

end
