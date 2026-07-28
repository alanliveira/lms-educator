FactoryBot.define do
  factory :company_course do
    company
    course
    can_be_viewed { false }
  end
end
