class RemoveUniqueConstraintNameFromDepartments < ActiveRecord::Migration[8.0]
  def change
    remove_index :departments, :name
    add_index :departments, [:name] #tambahkan hanya index untuk optimasi proses pencarian
  end
end
