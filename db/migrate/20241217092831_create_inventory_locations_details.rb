class CreateInventoryLocationsDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_locations_details, id: :uuid do |t|
      t.references :inventory_location, null: false, foreign_key: true, type: :uuid
      t.references :storage_unit, null: false, foreign_key: true, type: :uuid
      t.string :label, null: false, limit: 100

      t.timestamps
    end

    add_index :inventory_locations_details, [ :storage_unit_id, :label ], unique: true
  end
end
