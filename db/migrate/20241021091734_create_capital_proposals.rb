class CreateCapitalProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :capital_proposals, id: :uuid do |t|
      t.string :number, null: false, limit: 100
      t.string :real_number, limit: 100
      t.references :capital_proposal_type, null: false, foreign_key: true, type: :uuid
      t.references :capital_proposal_group, null: false, foreign_key: true, type: :uuid
      t.references :site, null: false, foreign_key: true, type: :uuid
      t.references :department, null: false, foreign_key: true, type: :uuid
      t.datetime :date, null: false
      t.string :description, null: false
      t.decimal :equiv_amount, precision: 18, scale: 2, null: false
      t.decimal :rate, precision: 18, scale: 2, null: false
      t.decimal :amount, precision: 18, scale: 2, null: false
      t.string :status, limit: 100, null: false
      t.string :budget_ref_number, limit: 100, null: false
      t.decimal :budget_amount, precision: 18, scale: 2, null: false

      t.string :created_by
      t.string :request_id
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
  end
end
