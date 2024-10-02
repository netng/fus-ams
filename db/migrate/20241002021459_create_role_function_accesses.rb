class CreateRoleFunctionAccesses < ActiveRecord::Migration[8.0]
  def change
    create_table :role_function_accesses, id: :uuid do |t|
      t.references :role, null: false, foreign_key: true, type: :uuid
      t.references :function_access, null: false, foreign_key: true, type: :uuid
      t.boolean :allow_create, default: false
      t.boolean :allow_read, default: false
      t.boolean :allow_update, default: false
      t.boolean :allow_delete, default: false
      t.boolean :allow_confirm, default: false
      t.boolean :allow_cancel_confirm, default: false

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :role_function_accesses, [:role_id, :function_access_id], unique: true
  end
end
