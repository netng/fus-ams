class CreateRequestForPurchaseDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :request_for_purchase_details, id: :uuid do |t|
      t.integer :qty
      t.datetime :tentative_date
      t.datetime :confirm_date
      t.string :specs, limit: 500
      t.references :currency, null: true, foreign_key: true, type: :uuid
      t.decimal :rate, precision: 18, scale: 2
      t.references :request_for_purchase, null: true, foreign_key: true, type: :uuid
      t.decimal :price, precision: 18, scale: 2
      t.decimal :sub_total, precision: 18, scale: 2
      t.string :status, limit: 100

      t.timestamps
    end
  end
end
