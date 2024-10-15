class AddIdSiteStatToSiteStats < ActiveRecord::Migration[8.0]
  def change
    add_column :site_stats, :id_site_stat, :string
    add_index :site_stats, [:id_site_stat], unique: true
  end
end
