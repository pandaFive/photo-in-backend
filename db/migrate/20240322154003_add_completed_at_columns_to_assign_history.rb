class AddCompletedAtColumnsToAssignHistory < ActiveRecord::Migration[7.1]
  def change
    add_column :assign_histories, :completed_at, :datetime
  end
end
