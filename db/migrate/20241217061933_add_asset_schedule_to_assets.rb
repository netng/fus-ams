class AddAssetScheduleToAssets < ActiveRecord::Migration[8.0]
  def change
    add_reference :assets, :asset_schedule, null: true, foreign_key: true, type: :uuid
  end
end
