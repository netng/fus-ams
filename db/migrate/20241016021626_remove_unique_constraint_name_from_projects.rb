class RemoveUniqueConstraintNameFromProjects < ActiveRecord::Migration[8.0]
  def change
    remove_index :projects, :name
    add_index :projects, [:name]
  end
end
