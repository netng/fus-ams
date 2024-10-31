class CreateAssetClasses < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_classes, id: :uuid do |t|
      t.string :id_asset_class, null: false, limit: 100
      t.string :name, null: false, limit: 100
      t.references :project, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :asset_classes, [:id_asset_class], unique: true
  end
end
