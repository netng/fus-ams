class AddSiteDefaultToInventoryLocations < ActiveRecord::Migration[8.0]
  def change
    add_reference :inventory_locations, :site_default, null: false, foreign_key: true, type: :uuid
  end
end
