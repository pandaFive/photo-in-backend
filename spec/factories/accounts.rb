FactoryBot.define do
  factory :account do
    role { "admin" }
    password { "password" }
    name { "name" }
    capacity { 3 }
  end

  factory :account_member, class: "Account" do
    role { "member" }
    password { "password" }
    name { "name" }
    capacity { 3 }
  end
end
