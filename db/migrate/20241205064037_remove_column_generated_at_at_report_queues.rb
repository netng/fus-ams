class RemoveColumnGeneratedAtAtReportQueues < ActiveRecord::Migration[8.0]
  def change
    remove_column :report_queues, :generated_at
  end
end
