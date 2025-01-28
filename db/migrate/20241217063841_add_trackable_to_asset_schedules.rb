class AddTrackableToAssetSchedules < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_schedules, :created_by, :string
    add_column :asset_schedules, :request_id, :string
    add_column :asset_schedules, :user_agent, :string
    add_column :asset_schedules, :ip_address, :string
  end
end
