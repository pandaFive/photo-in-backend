class ModifyComments3 < ActiveRecord::Migration[7.1]
  def change
    remove_column :comments, :assign_cycle_id, :bigint

    add_column :comments, :task_id, :bigint, null: false

    add_index :comments, :task_id
  end
end
