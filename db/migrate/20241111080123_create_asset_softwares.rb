class CreateAssetSoftwares < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_softwares, id: :uuid do |t|
      t.references :asset, null: false, foreign_key: true, type: :uuid
      t.references :software, null: false, foreign_key: true, type: :uuid
      t.string :license

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
  end
end
