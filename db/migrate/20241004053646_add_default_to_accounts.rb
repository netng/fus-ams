class AddDefaultToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :default, :boolean
  end
end
