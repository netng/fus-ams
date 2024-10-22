class CreateCurrencies < ActiveRecord::Migration[8.0]
  def change
    create_table :currencies, id: :uuid do |t|
      t.string :id_currency, null: false
      t.string :name, null: false

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :currencies, [:id_currency], unique: true
  end
end
