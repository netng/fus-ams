class InventoryLocation < ApplicationRecord
  belongs_to :site

  has_many :rooms, inverse_of: :inventory_location, dependent: :destroy
  accepts_nested_attributes_for :rooms, allow_destroy: true, reject_if: :all_blank

  has_many :inventory_locations_details, dependent: :restrict_with_error

  before_validation :strip_and_upcase_floor
  # Validasi untuk kombinasi floor dan site
  validates :floor, uniqueness: {
    scope: :site_id,
    case_sensitive: false,
    message: ->(object, _data) do
      I18n.t(
        "custom.errors.uniqueness_scope",
        field: object.class.human_attribute_name(:floor),
        related_model: object.site.class.model_name.human
      )
    end
  }

  validates :description, length: { maximum: 500 }

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "created_at", "created_by", "description", "floor", "id", "id_value", "ip_address", "request_id", "site_id", "updated_at", "user_agent" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "inventory_locations_details", "rooms", "site" ]
  end

  private
    def strip_and_upcase_floor
      if floor.present?
        self.floor = floor.strip.gsub(/\s+/, " ").upcase
      end
    end
end
