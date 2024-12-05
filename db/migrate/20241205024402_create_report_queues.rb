class CreateReportQueues < ActiveRecord::Migration[8.0]
  def change
    create_table :report_queues, id: :uuid do |t|
      t.string :name, limit: 100, null: false
      t.string :file_path, null: false
      t.datetime :generated_at
      t.references :generated_by, null: false, foreign_key: { to_table: :accounts }, type: :uuid
      t.integer :download_count
      t.string :last_downloaded_by, limit: 100
      t.datetime :last_downloaded_at


      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
  end
end
