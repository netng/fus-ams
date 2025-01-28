class CreateInventories < ActiveRecord::Migration[8.0]
  def change
    create_table :inventories, id: :uuid do |t|
      t.references :site, null: false, foreign_key: true, type: :uuid
      t.references :asset, null: false, foreign_key: true, type: :uuid
      t.references :rooms_storage_units_bin, null: false, foreign_key: true, type: :uuid
      t.string :status, limit: 100, default: "AVAILABLE" # AVAILABLE, MOVED

      t.timestamps
    end

    add_index :inventories, [ :site_id, :asset_id ], unique: true
  end
end
