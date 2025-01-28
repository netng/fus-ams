class InventoryLocationsDetail < ApplicationRecord
  belongs_to :inventory_location
  belongs_to :storage_unit

  before_validation :strip_and_upcase_label

  validates :label, uniqueness: {
    scope: :storage_unit_id,
    message: ->(object, _data) do
      I18n.t(
        "custom.errors.uniqueness_scope",
        field: object.class.human_attribute_name(:label),
        related_model: object.storage_unit.class.model_name.human
      )
    end
  }

  private
    def strip_and_upcase_label
      if label.present?
        self.label = label.strip.gsub(/\s+/, ' ').upcase
      end
    end
end
