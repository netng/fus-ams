class AssetsInventoryLocationsDetail < ApplicationRecord
  belongs_to :asset
  belongs_to :inventory_location_detail
end
