class RemoveLabelPathFromFunctionAccesses < ActiveRecord::Migration[8.0]
  def change
    remove_column :function_accesses, :label
    remove_column :function_accesses, :path
  end
end
