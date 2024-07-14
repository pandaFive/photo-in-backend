class ModifyCommentsTable < ActiveRecord::Migration[7.1]
  def change
    remove_index :comments, :task_id

    add_column :comments, :assign_cycle_id, :integer

    add_index :comments, :assign_cycle_id
  end
end
