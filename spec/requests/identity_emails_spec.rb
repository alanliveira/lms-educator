require "rails_helper"

RSpec.describe "Identity emails", type: :request do
  describe "GET /identity/email/edit" do
    it "renders the email edit form" do
      company = create(:company)
      user = create(:user, company: company)
      sign_in(user)

      get edit_identity_email_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /identity/email" do
    it "updates the current user's email" do
      company = create(:company)
      user = create(:user, company: company, email: "before@example.test")
      sign_in(user)

      patch identity_email_path, params: {
        email: "after@example.test",
        password_challenge: TestPassword::VALUE
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.email).to eq("after@example.test")
      expect(user).not_to be_verified
    end

    it "renders errors when the password challenge is invalid" do
      company = create(:company)
      user = create(:user, company: company, email: "kept@example.test")
      sign_in(user)

      patch identity_email_path, params: {
        email: "changed@example.test",
        password_challenge: "wrong-password"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.email).to eq("kept@example.test")
    end

    it "redirects without resending verification when the email is unchanged" do
      company = create(:company)
      user = create(:user, company: company, email: "same@example.test")
      sign_in(user)

      patch identity_email_path, params: {
        email: "same@example.test",
        password_challenge: TestPassword::VALUE
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.email).to eq("same@example.test")
    end
  end
end
