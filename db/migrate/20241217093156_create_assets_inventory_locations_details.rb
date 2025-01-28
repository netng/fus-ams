class CreateAssetsInventoryLocationsDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :assets_inventory_locations_details, id: :uuid do |t|
      t.references :asset, null: false, foreign_key: true, type: :uuid
      t.references :inventory_locations_detail, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :assets_inventory_locations_details, [ :asset_id, :inventory_locations_detail_id ], unique: true
  end
end
