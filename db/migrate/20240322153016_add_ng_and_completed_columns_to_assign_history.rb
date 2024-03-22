class AddNgAndCompletedColumnsToAssignHistory < ActiveRecord::Migration[7.1]
  def change
    add_column :assign_histories, :ng, :boolean
    add_column :assign_histories, :completed, :boolean

    add_index :assign_histories, :ng
    add_index :assign_histories, :completed
  end
end
