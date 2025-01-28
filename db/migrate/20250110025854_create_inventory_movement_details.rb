class CreateInventoryMovementDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_movement_details, id: :uuid do |t|
      t.references :inventory_movement, null: false, foreign_key: true, type: :uuid
      t.references :inventory, null: false, foreign_key: true, type: :uuid

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
  end
end
