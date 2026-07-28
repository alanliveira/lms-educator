require "rails_helper"

RSpec.describe "Identity email verifications", type: :request do
  describe "GET /identity/email_verification" do
    it "verifies the email for a valid token" do
      company = create(:company, subdomain: "verified-company")
      user = create(:user, company: company, verified: false)
      sid = user.generate_token_for(:email_verification)
      host! "#{company.subdomain}.lvh.me"

      get identity_email_verification_path, params: { sid: sid }

      expect(response).to redirect_to(root_path)
      expect(user.reload).to be_verified
    end

    it "redirects invalid tokens" do
      create(:company)

      get identity_email_verification_path, params: { sid: "invalid" }

      expect(response).to redirect_to(edit_identity_email_path)
    end
  end

  describe "POST /identity/email_verification" do
    it "resends verification instructions for the current user" do
      company = create(:company)
      user = create(:user, company: company)
      sign_in(user)

      post identity_email_verification_path

      expect(response).to redirect_to(root_path)
    end
  end
end
