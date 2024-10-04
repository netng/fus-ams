class RemoveAccountRolesTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :account_roles
  end

  def down
    create_table :account_roles, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :role, null: false, foreign_key: true, type: :uuid
      t.boolean :active, default: false

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :account_roles, [:account_id, :role_id], unique: true
  end
end
