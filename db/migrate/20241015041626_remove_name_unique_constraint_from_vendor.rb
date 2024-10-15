class RemoveNameUniqueConstraintFromVendor < ActiveRecord::Migration[8.0]
  def change
    remove_index :vendors, column: :name
    add_index :vendors, [:name]
  end
end
