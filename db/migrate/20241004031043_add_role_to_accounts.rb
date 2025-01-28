class AddRoleToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_reference :accounts, :role, null: false, foreign_key: true, type: :uuid
  end
end
