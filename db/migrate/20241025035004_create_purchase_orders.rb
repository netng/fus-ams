class CreatePurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_orders, id: :uuid do |t|
      t.string :number, null: false, limit: 100
      t.datetime :date, null: false
      t.references :vendor, null: false, foreign_key: true, type: :uuid
      t.references :request_for_purchase, null: false, foreign_key: true, type: :uuid
      t.datetime :delivery_date, null: false
      t.references :ship_to_site, null: false, foreign_key: { to_table: :sites }, type: :uuid
      t.string :payment_remarks, limit: 100
      t.string :description, limit: 500
      t.string :status, limit: 100
      t.references :currency, null: false, foreign_key: true, type: :uuid
      t.decimal :amount_by_currency, precision: 18, scale: 2
      t.decimal :rate, precision: 18, scale: 2
      t.decimal :amount_by_rate, precision: 18, scale: 2

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :purchase_orders, [:number], unique: true
  end
end
