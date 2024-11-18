class AddGroupToRoutePaths < ActiveRecord::Migration[8.0]
  def change
    add_column :route_paths, :group, :string, limit: 100
    add_column :route_paths, :sort, :integer, default: 0
  end
end
