class CreateDeliveryOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_orders, id: :uuid do |t|
      t.string :number, null: false, limit: 100
      t.datetime :date, null: false
      t.references :purchase_order, null: true, foreign_key: true, type: :uuid
      t.datetime :warranty_expired
      t.string :description, limit: 500

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :delivery_orders, [:number], unique: true
  end
end
