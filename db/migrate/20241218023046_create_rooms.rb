class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms, id: :uuid do |t|
      t.string :name, null: false, limit: 100
      t.string :description, limit: 500

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :rooms, [ :name ], unique: true
  end
end
