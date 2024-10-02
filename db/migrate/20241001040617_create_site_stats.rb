class CreateSiteStats < ActiveRecord::Migration[8.0]
  def change
    create_table :site_stats, id: :uuid do |t|
      t.string :name, null: false
      t.string :description
      
      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :site_stats, [:name], unique: true
  end
end
