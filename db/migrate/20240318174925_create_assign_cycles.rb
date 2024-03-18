class CreateAssignCycles < ActiveRecord::Migration[7.1]
  def change
    create_table :assign_cycles do |t|
      t.references :task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
