class CreateRoomsStorageUnitsBins < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms_storage_units_bins, id: :uuid do |t|
      t.references :rooms_storage_unit, null: false, foreign_key: true, type: :uuid
      t.string :label, null: false, limit: 100
      t.string :description, limit: 500

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :rooms_storage_units_bins, [ :label, :rooms_storage_unit_id ], unique: true
  end
end
