FactoryBot.define do
  factory :payment do
    association :subscription
    initial_payment { nil }
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
  end
end
