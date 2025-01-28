class AddIndexIdSiteDefaultToSiteDefaults < ActiveRecord::Migration[8.0]
  def change
    add_index :site_defaults, [:id_user_site_default]
  end
end
