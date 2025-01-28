class CreateAssetImportQueues < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_import_queues, id: :uuid do |t|
      t.string :job_id, null: false
      t.string :error_messages
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.decimal :execution_time, precision: 5, scale: 2


      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :asset_import_queues, [ :job_id ], unique: true
  end
end
