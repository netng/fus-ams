class RemoveUniqueConstraintNameFromSites < ActiveRecord::Migration[8.0]
  def change
    remove_index :sites, :name
    add_index :sites, [:name]
  end
end
