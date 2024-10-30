class CreatePoDeliverySites < ActiveRecord::Migration[8.0]
  def change
    create_table :po_delivery_sites, id: :uuid do |t|
      t.string :po_delivery_site_id, null: false, limit: 100
      t.string :name, limit: 100

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
    
    add_index :po_delivery_sites, [:po_delivery_site_id], unique: true
  end
end
