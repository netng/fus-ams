class AddParentToRoutePaths < ActiveRecord::Migration[8.0]
  def change
    add_column :route_paths, :parent, :string, limit: 100
  end
end
