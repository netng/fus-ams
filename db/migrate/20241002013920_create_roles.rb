class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :name, null: false
      t.string :description
      t.boolean :active, default: false

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :roles, [:name], unique: true
  end
end
