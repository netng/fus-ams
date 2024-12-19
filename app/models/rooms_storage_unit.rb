class RoomsStorageUnit < ApplicationRecord
  belongs_to :room
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

  private
    def strip_and_upcase_label
      if label.present?
        self.label = label.strip.gsub(/\s+/, " ").upcase
      end
    end
end
