class ChangeUniqueConstraintAtRooms < ActiveRecord::Migration[8.0]
  def change
    remove_index :rooms, :name
    add_index :rooms, [ :name, :inventory_location_id ], unique: true
  end
end
