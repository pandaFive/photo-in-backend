# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

["x", "y", "z"].each do |ele|
  Area.create(name: ele)
end

Account.create(name: "管理者", password: "password", role: 0, capacity: 0)

["加藤", "佐藤", "鈴木"].each_with_index do |man, index|
  a = Account.create(name: man, password: "password", role: 1, capacity: index)
  a.add_area(Area.find(index + 1))
end

["タスク01", "タスク02", "タスク03"].each_with_index do |title, index|
  t = Task.new(area_id: index + 1, task_title: title)
  t.save
  c = t.create_new_cycle

  c.assign
end
