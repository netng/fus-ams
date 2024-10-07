class AddIndexPhoneNumberFaxNumberContactPersonEmailToVendors < ActiveRecord::Migration[8.0]
  def change
    add_index :vendors, [:phone_number, :fax_number, :contact_person, :email]
  end
end
