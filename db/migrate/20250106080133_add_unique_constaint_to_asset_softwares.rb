class AddUniqueConstaintToAssetSoftwares < ActiveRecord::Migration[8.0]
  def change
    remove_index :asset_softwares, :asset_id
    remove_index :asset_softwares, :software_id
    add_index :asset_softwares, [ :asset_id, :software_id ], unique: true
  end
end
