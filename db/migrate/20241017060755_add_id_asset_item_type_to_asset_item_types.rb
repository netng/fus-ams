class AddIdAssetItemTypeToAssetItemTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_item_types, :id_asset_item_type, :string, null: false
    add_index :asset_item_types, [:id_asset_item_type], unique: true
  end
end
