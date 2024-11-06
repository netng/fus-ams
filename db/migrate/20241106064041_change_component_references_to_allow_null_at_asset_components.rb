class ChangeComponentReferencesToAllowNullAtAssetComponents < ActiveRecord::Migration[8.0]
  def change
    change_column :asset_components, :component_id, :uuid, null: true
  end
end
