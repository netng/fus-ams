class AddIdSiteGroupToSiteGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :site_groups, :id_site_group, :string, null: false
    add_index :site_groups, [:id_site_group], unique: true
  end
end
