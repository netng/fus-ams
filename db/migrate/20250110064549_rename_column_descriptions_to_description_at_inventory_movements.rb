class RenameColumnDescriptionsToDescriptionAtInventoryMovements < ActiveRecord::Migration[8.0]
  def change
    rename_column :inventory_movements, :descriptions, :description
  end
end
