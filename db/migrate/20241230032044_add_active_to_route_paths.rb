class AddActiveToRoutePaths < ActiveRecord::Migration[8.0]
  def change
    add_column :route_paths, :active, :boolean, default: true
  end
end
