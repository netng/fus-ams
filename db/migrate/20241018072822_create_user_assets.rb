class CreateUserAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :user_assets, id: :uuid do |t|
      t.string :id_user_asset, null: false
      t.string :aztec_code
      t.string :username
      t.string :email
      t.references :site, null: false, foreign_key: true, type: :uuid
      t.references :department, null: true, foreign_key: true, type: :uuid
      t.string :location
      t.string :floor
      t.string :description

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :user_assets, [:id_user_asset], unique: true
  end
end
