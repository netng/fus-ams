class Room < ApplicationRecord
  include Trackable

  belongs_to :inventory_location

  has_many :rooms_storage_units, inverse_of: :room, dependent: :destroy
  accepts_nested_attributes_for :rooms_storage_units, allow_destroy: true, reject_if: :all_blank

  before_validation :strip_and_upcase_name

  validates :description, length: { maximum: 500 }

  # Validasi untuk kombinasi name dan inventory_location_id
  validates :name, uniqueness: {
    scope: :inventory_location_id,
    case_sensitive: false,
    message: ->(object, _data) do
      I18n.t(
        "custom.errors.uniqueness_scope",
        field: object.class.human_attribute_name(:name),
        related_model: object.inventory_location.class.model_name.human
      )
    end
  }

  private
    def strip_and_upcase_name
      if name.present?
        self.name = name.strip.gsub(/\s+/, " ").upcase
      end
    end
end
