class ChangeStatusToNotNullAtPurchaseOrdersAndRequestForPurchases < ActiveRecord::Migration[8.0]
  def change
    change_column :purchase_orders, :status, :string, null: false
    change_column :request_for_purchases, :status, :string, null: false
  end
end
