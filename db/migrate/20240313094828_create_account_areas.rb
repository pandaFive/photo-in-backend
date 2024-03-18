class CreateAccountAreas < ActiveRecord::Migration[7.1]
  def change
    create_table :account_areas do |t|
      t.references :account, null: false, foreign_key: true
      t.references :area, null: false, foreign_key: true

      t.timestamps
    end
  end
end
