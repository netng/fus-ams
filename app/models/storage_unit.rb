class StorageUnit < ApplicationRecord
  include Trackable

  has_many :inventory_locations_details, dependent: :restrict_with_error

  before_validation :strip_and_upcase_storage_unit_name

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "created_by", "description", "id", "ip_address", "name", "request_id", "updated_at", "user_agent" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "inventory_locations_details" ]
  end

  private
    def strip_and_upcase_storage_unit_name
      if name.present?
        self.name = name.strip.gsub(/\s+/, ' ').upcase
      end
    end
end
