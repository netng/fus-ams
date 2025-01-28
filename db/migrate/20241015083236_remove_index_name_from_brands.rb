# remove unique index
class RemoveIndexNameFromBrands < ActiveRecord::Migration[8.0]
  def change
    remove_index :brands, column: :name
    add_index :brands, [:name]
  end
end
