class AddSequenceNumberToAssetSoftwares < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_softwares, :sequence_number, :integer, null: false
  end
end
