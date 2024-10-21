class CreateCapitalProposalGroupHeaders < ActiveRecord::Migration[8.0]
  def change
    create_table :capital_proposal_group_headers, id: :uuid do |t|
      t.string :id_capital_proposal_group_header, null: false, limit: 100
      t.string :name, limit: 100

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    add_index :capital_proposal_group_headers, [:id_capital_proposal_group_header], unique: true
  end
end
