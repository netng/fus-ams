class DropTableInventoryLocations < ActiveRecord::Migration[8.0]
  def change
    drop_table :inventory_locations
  end
end
