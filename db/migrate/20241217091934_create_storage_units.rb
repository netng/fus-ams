class CreateStorageUnits < ActiveRecord::Migration[8.0]
  def change
    create_table :storage_units, id: :uuid do |t|
      t.string :name, null: false, limit: 100
      t.string :description, limit: 500

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :storage_units, [ :name ], unique: true
  end
end
