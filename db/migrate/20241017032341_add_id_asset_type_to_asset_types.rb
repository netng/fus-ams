class AddIdAssetTypeToAssetTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_types, :id_asset_type, :string, null: false
    add_index :asset_types, [:id_asset_type], unique: true
  end
end