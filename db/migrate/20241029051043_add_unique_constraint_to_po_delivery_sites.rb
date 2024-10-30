class AddUniqueConstraintToPoDeliverySites < ActiveRecord::Migration[8.0]
  def change
    remove_index :po_delivery_sites, :po_delivery_site_id

    rename_column :po_delivery_sites, :po_delivery_site_id, :id_po_delivery_site
    add_index :po_delivery_sites, [:id_po_delivery_site], unique: true
  end
end
