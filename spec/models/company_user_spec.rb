require "rails_helper"

RSpec.describe CompanyUser, type: :model do
  subject(:company_user) { build(:company_user) }

  it { is_expected.to belong_to(:company) }
  it { is_expected.to belong_to(:user) }

  it "does not allow the same user twice in a company" do
    company_user = create(:company_user)

    duplicate = build(
      :company_user,
      company: company_user.company,
      user: company_user.user
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end

  it "allows only one owner per company" do
    company = create(:company)
    create(:company_user, company: company, owner: true)

    duplicate_owner = build(:company_user, company: company, owner: true)

    expect(duplicate_owner).not_to be_valid
    expect(duplicate_owner.errors[:owner]).to be_present
  end
end
