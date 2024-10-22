class AddIndexToNumberAtRequestForPurchases < ActiveRecord::Migration[8.0]
  def change
    add_index :request_for_purchases, [:number], unique: true
  end
end
