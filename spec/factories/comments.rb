# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    content { "テストコメント" }
    association :account, factory: :account_member
    association :task
  end
end
