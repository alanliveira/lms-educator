FactoryBot.define do
  factory :certificate_issuance do
    certificate
    course { certificate.course }
    user
    completed_at { Time.current }
  end
end
