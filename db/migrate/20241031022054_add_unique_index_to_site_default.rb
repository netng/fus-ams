class AddUniqueIndexToSiteDefault < ActiveRecord::Migration[8.0]
  def change
    remove_index :site_defaults, :site_id
    add_index :site_defaults, [:site_id], unique: true
  end
end
