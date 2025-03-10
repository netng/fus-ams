class UserAsset < ApplicationRecord
  include Trackable
  include Downcaseable

  belongs_to :site
  belongs_to :department, optional: true

  has_many :assets, dependent: :restrict_with_error

  downcase_fields :email
  before_validation :strip_email_aztec_username

  validates :id_user_asset, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :aztec_code, length: { maximum: 100 }
  validates :username, length: { maximum: 100 }
  validates :email, length: { maximum: 100 }
  validates :location, length: { maximum: 100 }
  validates :floor, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_attributes(auth_object = nil)
    [ "aztec_code", "created_at", "department_id", "description", "email", "floor", "id", "id_user_asset", "location", "site_id", "updated_at", "username", "assets_count" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "department", "site" ]
  end

  private
    def strip_email_aztec_username
      if email.present?
        self.email = email.strip
      end

      if aztec_code.present?
        self.aztec_code = aztec_code.strip
      end

      if username.present?
        self.username = username.strip
      end
    end
end
