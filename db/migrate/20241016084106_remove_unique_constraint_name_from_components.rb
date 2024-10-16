class RemoveUniqueConstraintNameFromComponents < ActiveRecord::Migration[8.0]
  def change
    remove_index :components, :name
    add_index :components, [:name]
  end
end
