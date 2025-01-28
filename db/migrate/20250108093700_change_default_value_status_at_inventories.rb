class ChangeDefaultValueStatusAtInventories < ActiveRecord::Migration[8.0]
  def change
    change_column :inventories, :status, :string, default: "IN_STOCK"
  end
end
