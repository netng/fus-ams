class CreateInventoryLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_locations, id: :uuid do |t|
      t.string :id_inventory_location, limit: 100, null: false
      t.string :description, limit: 500
      t.integer :assets_count

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :inventory_locations, [ :id_inventory_location ], unique: true
  end
end
