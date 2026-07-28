require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /users" do
    it "lists all users for admins" do
      admin = create(:user, role: :admin, email: "admin-list@example.test")
      user = create(:user, email: "listed-user@example.test")

      sign_in(admin)
      get users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.full_name)
    end

    it "lists only company users for company accounts" do
      company = create(:company)
      other_company = create(:company)
      company_user = create(:user, company: company, role: :company)
      same_company_student = create(:user, company: company, role: :student, full_name: "Same Company")
      other_company_student = create(:user, company: other_company, role: :student, full_name: "Other Company")

      sign_in(company_user)
      get users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(same_company_student.full_name)
      expect(response.body).not_to include(other_company_student.full_name)
    end
  end

  describe "GET /users/new" do
    it "renders the new user form" do
      admin = create(:user, role: :admin)

      sign_in(admin)
      get new_user_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "user member actions" do
    it "renders show and edit screens" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      student = create(:user, company: company, role: :student)
      sign_in(company_user)

      get user_path(student)
      expect(response).to have_http_status(:ok)

      get edit_user_path(student)
      expect(response).to have_http_status(:ok)
    end

    it "toggles user status" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      student = create(:user, company: company, role: :student, active: false)
      sign_in(company_user)

      get status_user_path(student)

      expect(response).to be_redirect
      expect(student.reload).to be_active
    end

    it "renders errors when status update fails" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      student = create(:user, company: company, role: :student)
      sign_in(company_user)
      allow_any_instance_of(User).to receive(:save).and_return(false)

      get status_user_path(student)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "updates a user inside the current tenant scope" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      student = create(:user, company: company, role: :student, full_name: "Before")
      sign_in(company_user)

      patch user_path(student), params: {
        user: {
          email: student.email,
          department: student.department,
          full_name: "After"
        }
      }

      expect(response).to redirect_to(user_path(student))
      expect(student.reload.full_name).to eq("After")
    end

    it "renders errors when user update fails" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      student = create(:user, company: company, role: :student)
      sign_in(company_user)

      patch user_path(student), params: {
        user: {
          email: "invalid",
          department: "",
          full_name: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /users" do
    it "creates a user as an admin" do
      admin = create(:user, role: :admin)
      company = create(:company)
      sign_in(admin)

      expect do
        post users_path, params: {
          user: {
            email: "created-user@example.test",
            password: TestPassword::VALUE,
            department: "Education",
            full_name: "Created User",
            company_user_attributes: { company_id: company.id }
          }
        }
      end.to change(User, :count).by(1)

      created_user = User.find_by!(email: "created-user@example.test")
      expect(created_user.company).to eq(company)
      expect(response).to redirect_to(user_path(created_user))
    end

    it "renders errors for invalid params" do
      admin = create(:user, role: :admin)
      sign_in(admin)

      expect do
        post users_path, params: {
          user: {
            email: "invalid",
            password: "short",
            department: "",
            full_name: ""
          }
        }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /users/:id" do
    it "soft deletes a user inside the current company" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      student = create(:user, company: company, role: :student)
      sign_in(company_user)

      expect do
        delete user_path(student)
      end.to change { student.reload.deleted_at.present? }.from(false).to(true)

      expect(response).to redirect_to(users_path)
    end
  end
end
