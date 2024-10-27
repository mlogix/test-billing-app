FactoryBot.define do
  factory :allocation do
    association :subscription
    association :payment
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
  end
end
