class AddIndexStatusToRoutePaths < ActiveRecord::Migration[8.0]
  def change
    add_column :route_paths, :index, :boolean, default: false
  end
end
