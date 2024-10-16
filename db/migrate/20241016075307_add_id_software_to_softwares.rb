class AddIdSoftwareToSoftwares < ActiveRecord::Migration[8.0]
  def change
    add_column :softwares, :id_software, :string, null: false
    add_index :softwares, [:id_software], unique: true
  end
end
