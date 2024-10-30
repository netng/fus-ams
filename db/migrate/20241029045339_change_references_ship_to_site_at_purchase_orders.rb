class ChangeReferencesShipToSiteAtPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    remove_index :purchase_orders, :ship_to_site_id
    remove_reference :purchase_orders, :ship_to_site, foreign_key: { to_table: :sites }, type: :uuid

    add_reference :purchase_orders, :ship_to_site, null: false, foreign_key: { to_table: :po_delivery_sites }, type: :uuid
  end
end
