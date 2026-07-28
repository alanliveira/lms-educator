require "rails_helper"

RSpec.describe DashboardPolicy do
  it "allows active admins into the admin dashboard" do
    user = create(:user, role: :admin, active: true)

    expect(described_class.new(user, :dashboard).admin?).to be(true)
  end

  it "allows active students into the student dashboard" do
    company = create(:company)
    user = create(:user, company: company, role: :student, active: true)

    expect(described_class.new(user, :dashboard).student?).to be(true)
  end

  it "allows active company users into the company dashboard" do
    company = create(:company)
    user = create(:user, company: company, role: :company, active: true)

    expect(described_class.new(user, :dashboard).company?).to be(true)
  end

  it "rejects inactive users" do
    user = create(:user, role: :admin, active: false)
    policy = described_class.new(user, :dashboard)

    expect(policy.admin?).to be(false)
    expect(policy.student?).to be(false)
    expect(policy.company?).to be(false)
  end
end
