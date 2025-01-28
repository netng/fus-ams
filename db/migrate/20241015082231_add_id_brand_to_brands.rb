class AddIdBrandToBrands < ActiveRecord::Migration[8.0]
  def change
    add_column :brands, :id_brand, :string
    add_index :brands, [:id_brand], unique: true
  end
end
