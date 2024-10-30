class ChangeCurrencyToAllowNullAtPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    change_column :purchase_orders, :currency_id, :uuid, null: true
  end
end
