class AddColumnScheduletAtFinishedAtToReportQueues < ActiveRecord::Migration[8.0]
  def change
    add_column :report_queues, :scheduled_at, :datetime
    add_column :report_queues, :finished_at, :datetime
    add_column :report_queues, :execution_time, :decimal, precision: 5, scale: 2
  end
end
