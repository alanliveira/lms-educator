require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_one(:company_user).dependent(:destroy) }
    it { is_expected.to have_one(:company).through(:company_user) }
    it { is_expected.to have_many(:histories).dependent(:destroy) }
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_presence_of(:password) }
  end
end
