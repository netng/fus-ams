class CreateSiteGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :site_groups, id: :uuid do |t|
      t.string :name, null: false
      t.string :description
      t.references :project, null: false, foreign_key: true, type: :uuid
      
      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :site_groups, [:name], unique: true
  end
end
