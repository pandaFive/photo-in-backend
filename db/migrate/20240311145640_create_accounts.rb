class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :password_digest, null: false
      t.integer :capacity, null: false
      t.string :role, null: false

      t.timestamps
    end
  end
end
