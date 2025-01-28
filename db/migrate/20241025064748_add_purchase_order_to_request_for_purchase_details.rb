class AddPurchaseOrderToRequestForPurchaseDetails < ActiveRecord::Migration[8.0]
  def change
    add_reference :request_for_purchase_details, :purchase_order, null: true, foreign_key: true, type: :uuid
  end
end
