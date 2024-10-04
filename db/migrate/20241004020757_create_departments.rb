class CreateDepartments < ActiveRecord::Migration[8.0]
  def change
    create_table :departments, id: :uuid do |t|
      t.string :name, null: false
      t.string :floor
      t.string :description

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :departments, [:name], unique: true
  end
end
