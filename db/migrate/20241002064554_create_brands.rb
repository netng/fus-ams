class CreateBrands < ActiveRecord::Migration[8.0]
  def change
    create_table :brands, id: :uuid do |t|
      t.string :name, null: false
      t.string :description

      t.timestamps
    end

    add_index :brands, [:name], unique: true
  end
end
