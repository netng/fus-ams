class AddScheduleToAssets < ActiveRecord::Migration[8.0]
  def change
    add_column :assets, :schedule, :string, limit: 100
  end
end
