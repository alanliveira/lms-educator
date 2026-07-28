FactoryBot.define do
  factory :company do
    name { Faker::Company.unique.name }
    fantasy_name { "#{name} Fantasy" }
    cnpj { Faker::Number.number(digits: 14).to_s }
    address { Faker::Address.full_address }
    subdomain { name.parameterize }

    to_create { |company| company.save!(validate: false) }
  end
end
