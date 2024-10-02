class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :username, null: false
      t.string :password_digest, null: false
      t.datetime :confirmed_at
      t.boolean :active, default: false
      
      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :accounts, [:username], unique: true
  end
end
