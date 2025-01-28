class RemoveUniqueConstraintNameFromSoftwares < ActiveRecord::Migration[8.0]
  def change
    remove_index :softwares, :name
    add_index :softwares, [:name]
  end
end
