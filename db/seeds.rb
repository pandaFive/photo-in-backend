["x", "y", "z"].each do |ele|
  Area.create(name: ele)
end

Account.create(name: "管理者", password: "password", role: 0, capacity: 0)

["加藤", "佐藤", "鈴木"].each_with_index do |man, index|
  c = index * 2
  a = Account.create(name: man, password: "password", role: 1, capacity: c**3)
  a.add_area(Area.find(index + 1))
end

1.upto(30) do |num|
  1.upto(3) do |index|
    t = Task.new(area_id: index, task_title: "タスク#{num * index}")
    t.save
    c = t.create_new_cycle

    h = c.assign

    if h
      if rand < 0.5
        c.completed_test
      end
    end
  end
end
["タスク01", "タスク02", "タスク03"].each_with_index do |title, index|
  t = Task.new(area_id: index + 1, task_title: title)
  t.save
  c = t.create_new_cycle

  h = c.assign

  if h
    if rand < 0.5
      c.completed_test
    end
  end
end
