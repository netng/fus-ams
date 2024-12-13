class AddScheduleToDeliveryOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :delivery_orders, :schedule, :string, limit: 100
  end
end
