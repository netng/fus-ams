class ChangeAssetReferencesToAllowNullAtAssetComponents < ActiveRecord::Migration[8.0]
  def change
    change_column :asset_components, :asset_id, :uuid, null: true
  end
end
