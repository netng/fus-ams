class CreateInventoryMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_movements, id: :uuid do |t|
      t.string :id_inventory_movement, null: false, limit: 100
      t.string :type, null: false, limit: 100
      t.references :source_site, null: false, foreign_key: { to_table: :sites }, type: :uuid
      t.references :destination_site, null: true, foreign_key: { to_table: :sites }, type: :uuid
      t.references :user_asset, null: true, foreign_key: true, type: :uuid
      t.integer :quantity, default: 0
      t.string :status, default: "IN_PROGRESS"
      t.string :descriptions, limit: 500

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :inventory_movements, [ :id_inventory_movement ], unique: true
  end
end
