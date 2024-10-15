class RenameColumnVendorIdToIdVendorAtVendors < ActiveRecord::Migration[8.0]
  def change
    remove_index :vendors, :vendor_id
    rename_column :vendors, :vendor_id, :id_vendor
    add_index :vendors, [:id_vendor], unique: true
  end
end
