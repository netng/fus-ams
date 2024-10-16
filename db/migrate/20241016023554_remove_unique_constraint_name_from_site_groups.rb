class RemoveUniqueConstraintNameFromSiteGroups < ActiveRecord::Migration[8.0]
  def change
    remove_index :site_groups, :name
    add_index :site_groups, :name
  end
end