class AddDefaultValueToDownloadCountAtReportQueues < ActiveRecord::Migration[8.0]
  def change
    change_column :report_queues, :download_count, :integer, default: 0
  end
end
