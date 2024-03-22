class RemoveIsCompleteFromTasks < ActiveRecord::Migration[7.1]
  def change
    remove_column :tasks, :is_complete, :boolean
  end
end
