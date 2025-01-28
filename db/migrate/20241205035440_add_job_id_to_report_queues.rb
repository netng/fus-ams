class AddJobIdToReportQueues < ActiveRecord::Migration[8.0]
  def change
    add_column :report_queues, :job_id, :integer, null: false
  end
end
