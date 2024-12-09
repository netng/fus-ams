class AddDataCountToReportQueues < ActiveRecord::Migration[8.0]
  def change
    add_column :report_queues, :data_count, :integer, default: 0
  end
end
