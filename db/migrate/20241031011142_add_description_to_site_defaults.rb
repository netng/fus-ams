class AddDescriptionToSiteDefaults < ActiveRecord::Migration[8.0]
  def change
    add_column :site_defaults, :description, :string, limit: 500
  end
end
