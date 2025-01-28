class AddRoomsStorageUnitsBinIdToAssets < ActiveRecord::Migration[8.0]
  def change
    add_reference :assets, :rooms_storage_units_bin, null: true, foreign_key: true, type: :uuid
  end
end
