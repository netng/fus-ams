class CreateRoomsStorageUnits < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms_storage_units, id: :uuid do |t|
      t.references :room, null: false, foreign_key: true, type: :uuid
      t.references :storage_unit, null: false, foreign_key: true, type: :uuid
      t.string :label, null: false, limit: 100
      t.string :capacity, limit: 100
      t.string :description, limit: 500

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :rooms_storage_units, [ :label, :room_id, :storage_unit_id ], unique: true
  end
end
