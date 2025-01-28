class AddAssetsCountToUserAssets < ActiveRecord::Migration[8.0]
  def change
    add_column :user_assets, :assets_count, :integer, default: 0, null: false
  end
end
