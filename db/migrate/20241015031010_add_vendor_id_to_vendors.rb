class AddVendorIdToVendors < ActiveRecord::Migration[8.0]
  def change
    add_column :vendors, :vendor_id, :string
    add_index :vendors, [:vendor_id], unique: true
  end
end
