class CreateSiteDefaults < ActiveRecord::Migration[8.0]
  def change
    create_table :site_defaults, id: :uuid do |t|
      t.references :site, null: false, foreign_key: true, type: :uuid
      t.string :id_site_default
      t.string :name
      t.string :id_user_site_default

      t.timestamps
    end
  end
end
