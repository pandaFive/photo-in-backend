class CreateTagAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :tag_accounts do |t|
      t.references :tag, null: false, foreign_key: true, null: false
      t.references :account, null: false, foreign_key: true, null: false

      t.timestamps
    end
  end
end
