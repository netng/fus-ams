class AddUniqueConstraintToEmailAtAccounts < ActiveRecord::Migration[8.0]
  def change
    add_index :accounts, [ :email ], unique: true
  end
end
