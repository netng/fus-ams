class AddCurrencyToCapitalProposals < ActiveRecord::Migration[8.0]
  def change
    add_reference :capital_proposals, :currency, null: false, foreign_key: true, type: :uuid
  end
end
