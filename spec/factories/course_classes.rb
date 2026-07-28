FactoryBot.define do
  factory :course_class do
    course
    name { "Class #{Faker::Alphanumeric.alpha(number: 8)}" }
    description { Faker::Lorem.paragraph }
  end
end
