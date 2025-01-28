class AddPersonalBoardToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :purchase_orders, :approved_by, null: false, foreign_key: { to_table: :personal_boards }, type: :uuid
  end
end
