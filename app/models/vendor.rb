class Vendor < ApplicationRecord
  include Trackable
  include Downcaseable

  has_many :purchase_orders, dependent: :restrict_with_error

  downcase_fields :email
  before_validation :remove_trailing_whitespace
  before_validation :strip_and_upcase_id_vendor

  # validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :id_vendor, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :name, length: { maximum: 100 }
  validates :address1, length: { maximum: 500 }
  validates :address2, length: { maximum: 500 }
  validates :city, length: { maximum: 100 }
  validates :postal_code, length: { maximum: 100 }
  validates :phone_number, length: { maximum: 100 }
  validates :fax_number, length: { maximum: 100 }
  validates :contact_person, length: { maximum: 100 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 100 }, allow_nil: true, if: -> { email.present? }
  # validates :email, length: { maximum: 100 }, allow_nil: true
  validates :description, length: { maximum: 500 }



  def self.ransackable_attributes(auth_object = nil)
    [ "address1", "address2", "city", "contact_person", "created_at", "created_by", "description", "email", "fax_number", "id", "id_vendor", "ip_address", "name", "phone_number", "postal_code", "request_id", "updated_at", "user_agent" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private
    def remove_trailing_whitespace
      self.email = email.strip unless email.blank?
    end

    def strip_and_upcase_id_vendor
      if id_vendor.present?
        self.id_vendor = id_vendor.strip.upcase
      end
    end
end
