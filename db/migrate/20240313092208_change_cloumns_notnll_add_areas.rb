class ChangeCloumnsNotnllAddAreas < ActiveRecord::Migration[7.1]
  def change
    change_column_null :areas, :name, false
  end
end
