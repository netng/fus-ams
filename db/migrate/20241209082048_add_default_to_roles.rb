class AddDefaultToRoles < ActiveRecord::Migration[8.0]
  def change
    add_column :roles, :default, :boolean, default: false
  end
end
