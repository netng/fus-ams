class AddIdComponentToComponents < ActiveRecord::Migration[8.0]
  def change
    add_column :components, :id_component, :string, null: false
    add_index :components, [:id_component], unique: true
  end
end
