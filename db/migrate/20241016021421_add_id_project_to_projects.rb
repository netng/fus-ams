class AddIdProjectToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :id_project, :string, null: false
    add_index :projects, [:id_project], unique: true
  end
end
