class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.references :area, null: false, foreign_key: true, null: false
      t.string :task_title, null: false
      t.boolean :is_complete, null: false, default: false

      t.timestamps
    end
  end
end
