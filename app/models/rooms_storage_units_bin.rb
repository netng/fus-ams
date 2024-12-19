class RoomsStorageUnitsBin < ApplicationRecord
  belongs_to :rooms_storage_unit

  before_validation :strip_and_upcase_label

  validates :label, length: { maximum: 100 }, uniqueness: {
    scope: :rooms_storage_unit_id,
    case_sensitive: false,
    message: ->(object, _data) do
      I18n.t("custom.errors.nested_uniqueness_scope")
    end
  }

  validates :description, length: { maximum: 500 }


  private
    def strip_and_upcase_label
      if label.present?
        self.label = label.strip.gsub(/\s+/, " ").upcase
      end
    end
end
