class CreateCapitalProposalGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :capital_proposal_groups, id: :uuid do |t|
      t.string :id_capital_proposal_group, null: false, limit: 100
      t.string :name, limit: 100
      t.references :capital_proposal_group_header, null: false, foreign_key: true, type: :uuid

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :capital_proposal_groups, [:id_capital_proposal_group], unique: true
  end
end
