class InventoryLocation < ApplicationRecord
  belongs_to :site

  has_many :inventory_locations_details, dependent: :restrict_with_error

  before_validation :strip_and_upcase_floor_and_room

  # Validasi untuk kombinasi floor dan site
  validates :floor, uniqueness: {
    scope: :site_id,
    message: ->(object, _data) do
      I18n.t(
        "custom.errors.uniqueness_scope",
        field: object.class.human_attribute_name(:floor),
        related_model: object.site.class.model_name.human
      )
    end
  }


  # Validasi untuk kombinasi room, floor dan site
  validates :room, uniqueness: {
    scope: %i[floor site_id],
    message: ->(object, _data) do
      I18n.t(
        "custom.errors.uniqueness_scope_with_floor",
        field: object.class.human_attribute_name(:room),
        floor: object.class.human_attribute_name(:floor),
        related_model: object.site.class.model_name.human
      )
    end
  }


  private
    def strip_and_upcase_floor_and_room
      if floor.present?
        self.floor = floor.strip.gsub(/\s+/, ' ').upcase
      end

      if room.present?
        self.room = room.strip.gsub(/\s+/, ' ').upcase
      end
    end
end
