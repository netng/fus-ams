class CreateAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :assets, id: :uuid do |t|
      t.datetime :tagging_date, null: false
      t.string :tagging_id, null: false, limit: 100
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.references :site, null: false, foreign_key: true, type: :uuid
      t.references :asset_model, null: false, foreign_key: true, type: :uuid
      t.references :user_asset, null: false, foreign_key: true, type: :uuid
      t.references :delivery_order, null: true, foreign_key: true, type: :uuid
      t.string :computer_name, limit: 100
      t.string :computer_ip, limit: 100
      t.string :cpu_sn, limit: 100
      t.string :monitor_sn, limit: 100
      t.string :keyboard_sn, limit: 100
      t.datetime :shipping_date
      t.string :description, limit: 500

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :assets, [:tagging_id], unique: true
  end
end
