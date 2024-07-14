areas = ["八王子", "町田", "昭島", "厚木", "横浜", "日野"]
areas.each do |ele|
  Area.create(name: ele)
end

Account.create(name: "管理者", password: "password", role: "admin", capacity: 0)

["加藤", "佐藤", "鈴木"].each_with_index do |man, index|
  c = index * 2
  a = Account.create(name: man, password: "password", role: "member", capacity: c**3)
  a.add_area(Area.find(index + 1))
  a.add_area(Area.find(index + 4))
end

["遠藤", "高木", "小山"].each_with_index do |man, index|
  c = index * 2
  a = Account.create(name: man, password: "password", role: "member", capacity: c**3)
  a.add_area(Area.find(index + 1))
  a.add_area(Area.find(6 - index))
end

1.upto(15) do |num|
  1.upto(6) do |index|
    area_index = index - 1
    t = Task.new(area_id: index, task_title: "#{areas[area_index]}xxx#{num}")
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
