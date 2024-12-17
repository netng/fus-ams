class CreateInventoryLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_locations, id: :uuid do |t|
      t.string :floor, null: false, limit: 100
      t.references :site, null: false, foreign_key: true, type: :uuid
      t.string :room, null: false, limit: 100
      t.string :description, limit: 500
      t.boolean :active

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :inventory_locations, [ :floor, :site_id ], unique: true
    add_index :inventory_locations, [ :floor, :site_id, :room ], unique: true
  end
end
