FactoryBot.define do
  factory :company_user do
    company
    user
    owner { false }
  end
end
