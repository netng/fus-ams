class RenameColumnTypeAtInventoryMovementsToMovementType < ActiveRecord::Migration[8.0]
  def change
    rename_column :inventory_movements, :type, :movement_type
  end
end
