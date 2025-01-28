class RemoveUniqueConstraintNameFromAssetTypes < ActiveRecord::Migration[8.0]
  def change
    remove_index :asset_types, :name
    add_index :asset_types, [:name]
  end
end
