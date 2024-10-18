class AddIndexUsernameAztecCodeToUserAssets < ActiveRecord::Migration[8.0]
  def change
    add_index :user_assets, [:username, :aztec_code]
  end
end