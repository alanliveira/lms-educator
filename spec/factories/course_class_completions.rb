FactoryBot.define do
  factory :course_class_completion do
    user
    course_class
    completed_at { Time.current }
  end
end
