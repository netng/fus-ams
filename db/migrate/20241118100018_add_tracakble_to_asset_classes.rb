class AddTracakbleToAssetClasses < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_classes, :created_by, :string
    add_column :asset_classes, :request_id, :string
    add_column :asset_classes, :user_agent, :string
    add_column :asset_classes, :ip_address, :string
  end
end
