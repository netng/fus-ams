class RemoveUniqueConstraintNameFromComponentTypes < ActiveRecord::Migration[8.0]
  def change
    remove_index :component_types, :name
    add_index :component_types, [:name]
  end
end
