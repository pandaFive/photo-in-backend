class CreateNgHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :ng_histories do |t|
      t.references :assign_cycle, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
