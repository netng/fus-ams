class CreateAssetComponents < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_components, id: :uuid do |t|
      t.references :asset, null: false, foreign_key: true, type: :uuid
      t.references :component, null: false, foreign_key: true, type: :uuid
      t.string :serial_number, limit: 100

      t.timestamps
    end

    add_index :asset_components, [ :serial_number ]
  end
end
