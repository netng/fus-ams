class RemoveUniqueConstraintNameFromAssetModels < ActiveRecord::Migration[8.0]
  def change
    remove_index :asset_models, :name
    add_index :asset_models, [:name]
  end
end
