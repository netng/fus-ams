class AddRoomsStorageUnitsCountToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :rooms_storage_units_count, :integer, default: 0
  end
end
