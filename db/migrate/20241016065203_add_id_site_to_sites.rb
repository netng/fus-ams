class AddIdSiteToSites < ActiveRecord::Migration[8.0]
  def change
    add_column :sites, :id_site, :string, null: false
    add_index :sites, [:id_site], unique: true
  end
end
