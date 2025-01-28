class AddSiteToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_reference :accounts, :site, null: true, foreign_key: true, type: :uuid
  end
end
