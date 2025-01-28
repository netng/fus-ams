class AddIdDepartmentToDepartments < ActiveRecord::Migration[8.0]
  def change
    add_column :departments, :id_department, :string, null: false
    add_index :departments, [:id_department], unique: true
  end
end
