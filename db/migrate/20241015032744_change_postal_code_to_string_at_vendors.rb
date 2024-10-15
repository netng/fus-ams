class ChangePostalCodeToStringAtVendors < ActiveRecord::Migration[8.0]
  def change
    change_column :vendors, :postal_code, :string
  end
end
