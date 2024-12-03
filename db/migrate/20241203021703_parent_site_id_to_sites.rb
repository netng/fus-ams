class ParentSiteIdToSites < ActiveRecord::Migration[8.0]
  def change
    add_reference :sites, :parent_site, null: true, foreign_key: { to_table: :sites }, type: :uuid
  end
end
