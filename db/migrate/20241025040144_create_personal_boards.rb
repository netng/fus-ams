class CreatePersonalBoards < ActiveRecord::Migration[8.0]
  def change
    create_table :personal_boards, id: :uuid do |t|
      t.string :id_personal_board, limit: 100, null: false
      t.string :username, limit: 100, null: false

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :personal_boards, [:id_personal_board], unique: true
  end
end
