class CreateAssetItemTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_item_types, id: :uuid do |t|
      t.string :name, null: false
      t.references :asset_type, null: false, foreign_key: true, type: :uuid
      t.string :description

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :asset_item_types, [:name], unique: true
  end
end
