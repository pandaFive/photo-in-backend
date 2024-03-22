class AddDefaultValuesToNgAndCompletedColumns < ActiveRecord::Migration[7.1]
  def change
    change_column_default :assign_histories, :ng, false
    change_column_default :assign_histories, :completed, false
  end
end
