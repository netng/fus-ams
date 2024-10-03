class CreateVendors < ActiveRecord::Migration[8.0]
  def change
    create_table :vendors, id: :uuid do |t|
      t.string :name, null: false
      t.text :address1
      t.text :address2
      t.string :city
      t.integer :postal_code
      t.string :phone_number
      t.string :fax_number
      t.string :contact_person
      t.string :email
      t.string :description

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :vendors, [:name], unique: true
  end
end
