class RemoveIdSiteDefaultFromSiteDefaults < ActiveRecord::Migration[8.0]
  def change
    remove_column :site_defaults, :id_site_default
  end
end
