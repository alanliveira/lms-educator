FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { TestPassword::VALUE }
    password_confirmation { TestPassword::VALUE }
    full_name { Faker::Name.name }
    department { "Education" }
    active { true }
    verified { true }

    transient do
      company { nil }
      role { :student }
      owner { role == :company }
    end

    after(:create) do |user, evaluator|
      if evaluator.company
        create(:company_user, company: evaluator.company, user: user, owner: evaluator.owner)
      end

      user.remove_role(:student)
      user.add_role(evaluator.role)
    end
  end
end
