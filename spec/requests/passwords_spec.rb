require "rails_helper"

RSpec.describe "Passwords", type: :request do
  describe "GET /password/edit" do
    it "renders the password edit form" do
      company = create(:company)
      user = create(:user, company: company)
      sign_in(user)

      get edit_password_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /password" do
    it "updates the current user's password" do
      company = create(:company)
      user = create(:user, company: company)
      sign_in(user)

      patch password_path, params: {
        password_challenge: TestPassword::VALUE,
        password: "NewPassword1",
        password_confirmation: "NewPassword1"
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.authenticate("NewPassword1")).to be_truthy
    end

    it "renders errors when the password challenge is invalid" do
      company = create(:company)
      user = create(:user, company: company)
      sign_in(user)

      patch password_path, params: {
        password_challenge: "wrong-password",
        password: "NewPassword1",
        password_confirmation: "NewPassword1"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate(TestPassword::VALUE)).to be_truthy
    end
  end
end
