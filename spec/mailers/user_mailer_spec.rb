require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#password_reset" do
    it "sends reset instructions to the user" do
      user = create(:user)

      mail = described_class.with(user: user).password_reset

      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq("Resetar a sua senha")
      expect(mail.body.encoded).to include("sid=")
    end
  end

  describe "#email_verification" do
    it "sends verification instructions to the user" do
      company = create(:company, subdomain: "verify-company")
      user = create(:user, company: company)

      mail = described_class.with(user: user).email_verification

      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq("Valide o seu email")
      expect(mail.body.encoded).to include("verify-company")
    end

    it "falls back to the company created by the setup when the user has none" do
      create(:company, subdomain: Company::DEFAULT_SUBDOMAIN)
      user = create(:user)

      mail = described_class.with(user: user).email_verification

      expect(mail.to).to eq([user.email])
      expect(mail.body.encoded).to include(Company::DEFAULT_SUBDOMAIN)
    end
  end

  describe "#new_user" do
    it "notifies the company owner" do
      company = create(:company, subdomain: "owner-company")
      owner = create(:user, company: company, role: :company, email: "owner@example.test")
      user = create(:user, company: company, role: :student)

      mail = described_class.with(user: user).new_user

      expect(mail.to).to eq([owner.email])
      expect(mail.subject).to eq("Cadastro de novo funcionário")
      expect(mail.body.encoded).to include(user.full_name)
    end

    it "notifies the owner of the setup company when the user has none" do
      setup_company = create(:company, subdomain: Company::DEFAULT_SUBDOMAIN)
      owner = create(:user, company: setup_company, role: :company, email: "setup-owner@example.test")
      user = create(:user)

      mail = described_class.with(user: user).new_user

      expect(mail.to).to eq([owner.email])
      expect(mail.body.encoded).to include(user.full_name)
    end
  end
end
