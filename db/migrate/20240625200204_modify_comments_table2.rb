class ModifyCommentsTable2 < ActiveRecord::Migration[7.1]
  def change
    remove_column :comments, :task_id, :bigint
    remove_column :comments, :assign_cycle_id, :integer

    add_column :comments, :assign_cycle_id, :bigint, null: false
    add_index :comments, :assign_cycle_id
  end
end
