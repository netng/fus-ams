class InventoryLocation < ApplicationRecord
  include Trackable

  belongs_to :site_default

  before_validation :strip_and_upcase_id_inventory_location

  validates :id_inventory_location, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  private
    def strip_and_upcase_id_inventory_location
      if id_inventory_location.present?
        self.id_inventory_location = id_inventory_location.strip.upcase
      end
    end
end
