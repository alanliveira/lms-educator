require "rails_helper"

RSpec.describe "Identity password resets", type: :request do
  describe "GET /identity/password_reset/new" do
    it "renders the reset request form" do
      create(:company)

      get new_identity_password_reset_path

      expect(response).to have_http_status(:ok)
    end

    it "shows the company logo for the subdomain" do
      company = create(:company, subdomain: "password-logo")
      company.logo.attach(
        io: StringIO.new(File.binread(Rails.root.join("spec/fixtures/files/logo.png"))),
        filename: "logo.png",
        content_type: "image/png"
      )
      host! "#{company.subdomain}.lvh.me"

      get new_identity_password_reset_path

      expect(response.body).to include("alt=\"#{company.fantasy_name}\"")
    end
  end

  describe "POST /identity/password_reset" do
    it "sends reset instructions for verified users" do
      user = create(:user, verified: true)

      post identity_password_reset_path, params: { email: user.email }

      expect(response).to redirect_to(sign_in_path)
    end

    it "rejects unknown users" do
      create(:company)

      post identity_password_reset_path, params: { email: "missing@example.test" }

      expect(response).to redirect_to(new_identity_password_reset_path)
    end
  end

  describe "GET /identity/password_reset/edit" do
    it "renders the edit form for a valid token" do
      user = create(:user, verified: true)
      sid = user.generate_token_for(:password_reset)

      get edit_identity_password_reset_path, params: { sid: sid }

      expect(response).to have_http_status(:ok)
    end

    it "shows the company logo when resetting a password from its subdomain" do
      company = create(:company, subdomain: "password-reset-logo")
      company.logo.attach(
        io: StringIO.new(File.binread(Rails.root.join("spec/fixtures/files/logo.png"))),
        filename: "logo.png",
        content_type: "image/png"
      )
      user = create(:user, company: company, verified: true)
      host! "#{company.subdomain}.lvh.me"

      get edit_identity_password_reset_path, params: { sid: user.generate_token_for(:password_reset) }

      expect(response.body).to include("alt=\"#{company.fantasy_name}\"")
    end

    it "redirects invalid tokens" do
      create(:company)

      get edit_identity_password_reset_path, params: { sid: "invalid" }

      expect(response).to redirect_to(new_identity_password_reset_path)
    end
  end

  describe "PATCH /identity/password_reset" do
    it "updates the password for a valid token" do
      user = create(:user, verified: true)
      sid = user.generate_token_for(:password_reset)

      patch identity_password_reset_path, params: {
        sid: sid,
        password: "ResetPassword1",
        password_confirmation: "ResetPassword1"
      }

      expect(response).to redirect_to(sign_in_path)
      expect(user.reload.authenticate("ResetPassword1")).to be_truthy
    end

    it "renders errors for invalid password params" do
      user = create(:user, verified: true)
      sid = user.generate_token_for(:password_reset)

      patch identity_password_reset_path, params: {
        sid: sid,
        password: "short",
        password_confirmation: "different"
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
