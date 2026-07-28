require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /sign_up" do
    it "renders the registration form for a company subdomain" do
      company = create(:company, subdomain: "signup-company")
      host! "#{company.subdomain}.lvh.me"

      get sign_up_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Criar conta")
    end
  end

  describe "POST /sign_up" do
    it "creates an inactive user for the selected company" do
      company = create(:company, subdomain: "new-user-company")
      create(:user, company: company, role: :company, email: "owner-new-user@example.test")
      host! "#{company.subdomain}.lvh.me"

      expect do
        post sign_up_path, params: {
          user: {
            email: "new-user@example.test",
            password: TestPassword::VALUE,
            password_confirmation: TestPassword::VALUE,
            department: "Education",
            full_name: "New User",
            company_attributes: { id: company.id }
          }
        }
      end.to change(User, :count).by(1)

      user = User.find_by!(email: "new-user@example.test")
      expect(user.company).to eq(company)
      expect(user).not_to be_active
      expect(response).to redirect_to(sign_in_path)
    end

    it "renders errors for invalid params" do
      company = create(:company)
      host! "#{company.subdomain}.lvh.me"

      expect do
        post sign_up_path, params: {
          user: {
            email: "invalid",
            password: "short",
            password_confirmation: "different",
            department: "",
            full_name: "",
            company_attributes: { id: company.id }
          }
        }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
