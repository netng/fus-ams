class AddInventoryLocationToRooms < ActiveRecord::Migration[8.0]
  def change
    add_reference :rooms, :inventory_location, null: false, foreign_key: true, type: :uuid
  end
end
