class InventoryMovementDetail < ApplicationRecord
  belongs_to :inventory_movement
  belongs_to :inventory
end
