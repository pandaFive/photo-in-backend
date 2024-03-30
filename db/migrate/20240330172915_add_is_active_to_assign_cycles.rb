class AddIsActiveToAssignCycles < ActiveRecord::Migration[7.1]
  def change
    add_column :assign_cycles, :is_active, :boolean, null: false, default: true
    add_index :assign_cycles, :is_active
  end
end
