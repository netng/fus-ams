class CreateRequestForPurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :request_for_purchases, id: :uuid do |t|
      t.string :number, null: false, limit: 100
      t.references :capital_proposal, null: true, foreign_key: true, type: :uuid
      t.references :from_department, null: false, foreign_key: { to_table: :departments }, type: :uuid
      t.references :to_department, null: false, foreign_key: { to_table: :departments }, type: :uuid
      t.datetime :date, null: false
      t.string :material_code, null: false, limit: 100
      t.string :remarks, limit: 100
      t.string :issued_by, limit: 100
      t.string :authorized_by, limit: 100
      t.string :status, limit: 100, null: false

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
  end
end
