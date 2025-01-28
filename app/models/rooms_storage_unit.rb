class RoomsStorageUnit < ApplicationRecord
  belongs_to :room, counter_cache: true

  belongs_to :storage_unit

  has_one_attached :rooms_storage_unit_photo

  has_many :rooms_storage_units_bins, inverse_of: :rooms_storage_unit, dependent: :destroy
  accepts_nested_attributes_for :rooms_storage_units_bins, allow_destroy: true, reject_if: :all_blank

  before_validation :strip_and_upcase_label

  validates :capacity, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  validates :label, length: { maximum: 100 }, uniqueness: {
    scope: %w[room_id storage_unit_id],
    case_sensitive: false,
    message: ->(object, _data) do
      I18n.t("custom.errors.nested_uniqueness_scope")
    end
  }

  def self.ransackable_attributes(auth_object = nil)
    ["capacity", "created_at", "created_by", "description", "id", "ip_address", "label", "request_id", "room_id", "storage_unit_id", "updated_at", "user_agent"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["room", "rooms_storage_unit_photo_attachment", "rooms_storage_unit_photo_blob", "rooms_storage_units_bins", "storage_unit"]
  end
  
  private
    def strip_and_upcase_label
      if label.present?
        self.label = label.strip.gsub(/\s+/, " ").upcase
      end
    end
end
