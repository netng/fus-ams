class AddRoomCountToInventoryLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :inventory_locations, :rooms_count, :integer, default: 0
  end
end
