class CreateCompletedTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :completed_tasks do |t|
      t.references :task, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
