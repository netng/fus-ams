class CreateRoutePaths < ActiveRecord::Migration[8.0]
  def change
    create_table :route_paths, id: :uuid do |t|
      t.references :function_access, null: false, foreign_key: true, type: :uuid
      t.string :path, limit: 100, null: false
      t.string :label, limit: 100, null: false
      t.string :description, limit: 500

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :route_paths, [ :path ], unique: true
  end
end
