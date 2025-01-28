class AddIndexToCapitalProposals < ActiveRecord::Migration[8.0]
  def change
    add_index :capital_proposals, [:number], unique: true
  end
end
