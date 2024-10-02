class Account < ApplicationRecord
  include Trackable
  include Downcaseable

  has_secure_password


  downcase_fields :email
  downcase_fields :username

  validates :username, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9\-.]+\z/, message: I18n.t("custom.errors.invalid_username_format") }
  
  validates :password, length: { minimum: 3 }

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true
end
