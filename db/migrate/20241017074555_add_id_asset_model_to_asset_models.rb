class AddIdAssetModelToAssetModels < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_models, :id_asset_model, :string, null: false
    add_index :asset_models, [:id_asset_model], unique: true
  end
end
