require "rails_helper"

RSpec.describe Company, type: :model do
  it "validates normalized subdomain uniqueness" do
    create(:company, subdomain: "tenant")

    company = build(:company, subdomain: "TENANT")
    company.validate

    expect(company.errors[:subdomain]).to include("já está em uso")
  end

  it { is_expected.to validate_exclusion_of(:subdomain).in_array(%w[www]) }
end
