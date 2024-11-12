class AddAssetClassesToAssets < ActiveRecord::Migration[8.0]
  def change
    add_reference :assets, :asset_class, null: true, foreign_key: true, type: :uuid
  end
end
