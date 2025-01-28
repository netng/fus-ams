class AddDefaultValueToDefaultAtAccounts < ActiveRecord::Migration[8.0]
  def change
    change_column :accounts, :default, :boolean, default: false
  end
end
