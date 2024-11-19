class AddTrackableToAssetComponents < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_components, :created_by, :string
    add_column :asset_components, :request_id, :string
    add_column :asset_components, :user_agent, :string
    add_column :asset_components, :ip_address, :string
  end
end
