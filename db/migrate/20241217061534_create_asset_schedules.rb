class CreateAssetSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_schedules, id: :uuid do |t|
      t.string :name, limit: 100, null: false
      t.string :description, limit: 500

      t.timestamps
    end

    add_index :asset_schedules, [ :name ], unique: true
  end
end
