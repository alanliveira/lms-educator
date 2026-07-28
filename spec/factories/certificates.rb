FactoryBot.define do
  factory :certificate do
    course
    description { "Certificate description" }
    total_hours { 40 }
  end
end
