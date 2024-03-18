class CreateAssignHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :assign_histories do |t|
      t.references :account, null: false, foreign_key: true
      t.references :assign_cycle, null: false, foreign_key: true

      t.timestamps
    end
  end
end
