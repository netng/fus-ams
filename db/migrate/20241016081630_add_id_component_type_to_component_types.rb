class AddIdComponentTypeToComponentTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :component_types, :id_component_type, :string, null: false
    add_index :component_types, [:id_component_type], unique: true
  end
end
