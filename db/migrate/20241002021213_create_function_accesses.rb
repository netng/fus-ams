class CreateFunctionAccesses < ActiveRecord::Migration[8.0]
  def change
    create_table :function_accesses, id: :uuid do |t|
      t.string :code, null: false
      t.string :label, null: false
      t.string :path, null: false
      t.string :description
      t.boolean :admin, default: false
      t.boolean :active, default: false

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :function_accesses, [:code], unique: true
  end
end
