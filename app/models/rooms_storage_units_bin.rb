class RoomsStorageUnitsBin < ApplicationRecord
  belongs_to :rooms_storage_unit

  before_validation :strip_and_upcase_label

  has_one_attached :rooms_storage_units_bin_photo

  has_many :assets, dependent: :restrict_with_error


  validates :label, length: { maximum: 100 }, uniqueness: {
    scope: :rooms_storage_unit_id,
    case_sensitive: false,
    message: ->(object, _data) do
      I18n.t("custom.errors.nested_uniqueness_scope")
    end
  }

  validates :description, length: { maximum: 500 }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "created_by", "description", "id", "ip_address", "label", "request_id", "rooms_storage_unit_id", "updated_at", "user_agent"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["assets", "rooms_storage_unit", "rooms_storage_units_bin_photo_attachment", "rooms_storage_units_bin_photo_blob"]
  end


  private
    def strip_and_upcase_label
      if label.present?
        self.label = label.strip.gsub(/\s+/, " ").upcase
      end
    end
end
