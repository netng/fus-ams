class CreateCapitalProposalTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :capital_proposal_types, id: :uuid do |t|
      t.string :id_capital_proposal_type, null: false, limit: 100
      t.string :name, limit: 100

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :capital_proposal_types, [:id_capital_proposal_type], unique: true
  end
end
