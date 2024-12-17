class AddStatusToReportQueues < ActiveRecord::Migration[8.0]
  def change
    add_column :report_queues, :status, :boolean
  end
end
