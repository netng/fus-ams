class ChangeColumnJobIdAtReportQueuesToString < ActiveRecord::Migration[8.0]
  def change
    remove_column :report_queues, :job_id
    add_column :report_queues, :job_id, :string, null: false
  end
end
