class Account < ApplicationRecord
  include Trackable
  include Downcaseable

  has_secure_password

  belongs_to :role
  belongs_to :site

  has_many :report_queues, class_name: "ReportQueue", foreign_key: "generated_by_id", dependent: :destroy

  downcase_fields :email
  downcase_fields :username
  before_validation :remove_trailing_whitespace


  validates :username, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[a-zA-Z0-9\-.]+\z/, message: I18n.t("custom.errors.invalid_username_format") }

  validates :password, length: { minimum: 3 }, unless: -> { password.blank? }

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "confirmed_at", "created_at", "created_by", "default", "email", "id", "id_value", "ip_address", "name", "password_digest", "request_id", "role_id", "site_id", "updated_at", "user_agent", "username" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "role", "site" ]
  end

  private
    def remove_trailing_whitespace
      self.email = email.strip unless email.blank?
      self.username = username.strip unless username.blank?
    end
end
