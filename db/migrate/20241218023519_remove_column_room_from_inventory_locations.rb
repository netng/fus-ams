class RemoveColumnRoomFromInventoryLocations < ActiveRecord::Migration[8.0]
  def change
    remove_column :inventory_locations, :room
  end
end
