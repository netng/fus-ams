class CreateSites < ActiveRecord::Migration[8.0]
  def change
    create_table :sites, id: :uuid do |t|
      t.string :name, null: false
      t.references :site_stat, null: false, foreign_key: true, type: :uuid
      t.references :site_group, null: false, foreign_key: true, type: :uuid

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :sites, [:name], unique: true
  end
end
