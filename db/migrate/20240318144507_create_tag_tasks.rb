class CreateTagTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tag_tasks do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
