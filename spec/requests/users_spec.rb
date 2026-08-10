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

    it "shows the current role to admins editing a user" do
      admin = create(:user, role: :admin)
      company = create(:company)
      student = create(:user, company: company, role: :student)
      sign_in(admin)

      get edit_user_path(student)

      expect(response.body).to include("Role atual: Colaborador")
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

    it "lets an admin replace a user's role and company" do
      admin = create(:user, role: :admin)
      first_company = create(:company)
      second_company = create(:company)
      student = create(:user, company: first_company, role: :student)
      sign_in(admin)

      patch user_path(student), params: {
        user: {
          email: student.email,
          department: student.department,
          full_name: student.full_name,
          role: "company",
          company_user_attributes: { id: student.company_user.id, company_id: second_company.id }
        }
      }

      expect(response).to redirect_to(user_path(student))
      expect(student.reload.has_role?(:company)).to be(true)
      expect(student.has_role?(:student)).to be(false)
      expect(student.company).to eq(second_company)
    end

    it "prevents an admin from changing their own role" do
      admin = create(:user, role: :admin)
      company = create(:company)
      sign_in(admin)

      patch user_path(admin), params: {
        user: {
          email: admin.email,
          department: admin.department,
          full_name: admin.full_name,
          role: "student",
          company_user_attributes: { company_id: company.id }
        }
      }

      expect(response).to redirect_to(edit_user_path(admin))
      expect(admin.reload.has_role?(:admin)).to be(true)
    end

    it "prevents an admin from reclassifying a company owner" do
      admin = create(:user, role: :admin)
      company = create(:company)
      owner = create(:user, company: company, role: :company, owner: true)
      sign_in(admin)

      patch user_path(owner), params: {
        user: {
          email: owner.email,
          department: owner.department,
          full_name: owner.full_name,
          role: "student",
          company_user_attributes: { id: owner.company_user.id, company_id: company.id }
        }
      }

      expect(response).to redirect_to(edit_user_path(owner))
      expect(owner.reload.has_role?(:company)).to be(true)
    end

    it "lets a company user promote only a student from its own company" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      student = create(:user, company: company, role: :student)
      sign_in(company_user)

      patch user_path(student), params: {
        user: {
          email: student.email,
          department: student.department,
          full_name: student.full_name,
          role: "company"
        }
      }

      expect(response).to redirect_to(user_path(student))
      expect(student.reload.has_role?(:company)).to be(true)
    end

    it "prevents a company user from assigning the admin role" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      student = create(:user, company: company, role: :student)
      sign_in(company_user)

      patch user_path(student), params: {
        user: {
          email: student.email,
          department: student.department,
          full_name: student.full_name,
          role: "admin"
        }
      }

      expect(response).to redirect_to(edit_user_path(student))
      expect(student.reload.has_role?(:student)).to be(true)
    end

    it "prevents a company user from changing another company user" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      other_company_user = create(:user, company: company, role: :company)
      sign_in(company_user)

      patch user_path(other_company_user), params: {
        user: {
          email: other_company_user.email,
          department: other_company_user.department,
          full_name: "Changed"
        }
      }

      expect(response).to redirect_to(users_path)
      expect(other_company_user.reload.full_name).not_to eq("Changed")
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
