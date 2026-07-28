FactoryBot.define do
  factory :course do
    name { "Course #{Faker::Alphanumeric.alpha(number: 8)}" }
    description { Faker::Lorem.paragraph }
  end
end
