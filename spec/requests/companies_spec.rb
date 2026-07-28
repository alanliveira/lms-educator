require "rails_helper"

RSpec.describe "Companies", type: :request do
  def logo_upload
    fixture_file_upload("logo.png", "image/png")
  end

  def make_company_updatable(company)
    owner = create(:user, company: company, role: :company)
    company.logo.attach(
      io: StringIO.new("fake image"),
      filename: "logo.png",
      content_type: "image/png"
    )
    owner
  end

  describe "GET /companies" do
    it "lists companies for admins" do
      admin = create(:user, role: :admin)
      company = create(:company, name: "Listed Company")

      sign_in(admin)
      get companies_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(company.name)
    end

    it "paginates the company table" do
      admin = create(:user, role: :admin)
      first_company = create(:company, name: "First Company")
      second_company = create(:company, name: "Second Company")

      sign_in(admin)
      get companies_path, params: { page: 2, per: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(first_company.name)
      expect(response.body).not_to include(second_company.name)
    end
  end

  describe "company CRUD" do
    it "renders new, show, and edit screens" do
      admin = create(:user, role: :admin)
      company = create(:company)
      sign_in(admin)

      get new_company_path
      expect(response).to have_http_status(:ok)

      get company_path(company)
      expect(response).to have_http_status(:ok)

      get edit_company_path(company)
      expect(response).to have_http_status(:ok)
    end

    it "creates a company and owner user" do
      admin = create(:user, role: :admin)
      sign_in(admin)

      expect do
        post companies_path, params: {
          company: {
            name: "Created Company",
            fantasy_name: "Created Fantasy",
            cnpj: "12345678901234",
            address: "Created Address",
            subdomain: "created-company",
            logo: logo_upload,
            users_attributes: {
              "0" => {
                full_name: "Owner User",
                department: "Education",
                email: "owner-created@example.test",
                password: TestPassword::VALUE,
                active: true
              }
            }
          }
        }
      end.to change(Company, :count).by(1)
        .and change(User, :count).by(1)

      company = Company.find_by!(subdomain: "created-company")
      expect(company.owner.email).to eq("owner-created@example.test")
      expect(response).to redirect_to(company_path(company))
    end

    it "renders errors for invalid company params" do
      admin = create(:user, role: :admin)
      sign_in(admin)

      expect do
        post companies_path, params: {
          company: {
            name: "",
            fantasy_name: "",
            cnpj: "",
            address: "",
            subdomain: "",
            users_attributes: {
              "0" => {
                full_name: "",
                department: "",
                email: "invalid",
                password: "short"
              }
            }
          }
        }
      end.not_to change(Company, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "destroys a company" do
      admin = create(:user, role: :admin)
      company = create(:company)
      sign_in(admin)

      expect do
        delete company_path(company)
      end.to change { company.reload.deleted_at.present? }.from(false).to(true)

      expect(response).to redirect_to(companies_path)
    end
  end

  describe "company course access" do
    it "adds a course to a company" do
      admin = create(:user, role: :admin)
      company = create(:company)
      make_company_updatable(company)
      course = create(:course)
      sign_in(admin)

      expect do
        patch add_course_company_path(company), params: {
          company: {
            company_courses_attributes: {
              "0" => { course_id: course.id }
            }
          }
        }
      end.to change(company.company_courses, :count).by(1)

      expect(response).to redirect_to(company_path(company))
    end

    it "renders errors when adding a course fails" do
      admin = create(:user, role: :admin)
      company = create(:company)
      make_company_updatable(company)
      course = create(:course)
      sign_in(admin)
      allow_any_instance_of(Company).to receive(:update).and_return(false)

      patch add_course_company_path(company), params: {
        company: {
          company_courses_attributes: {
            "0" => { course_id: course.id }
          }
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "removes a course from a company" do
      admin = create(:user, role: :admin)
      company = create(:company)
      company_course = create(:company_course, company: company)
      sign_in(admin)

      expect do
        delete remove_course_from_company_path(company, company_course.course)
      end.to change { company.company_courses.exists?(company_course.id) }.from(true).to(false)

      expect(response).to redirect_to(company_path(company))
    end

    it "renders errors when removing a missing course association" do
      admin = create(:user, role: :admin)
      company = create(:company)
      course = create(:course)
      sign_in(admin)

      delete remove_course_from_company_path(company, course)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "toggles course visibility" do
      admin = create(:user, role: :admin)
      company = create(:company)
      company_course = create(:company_course, company: company, can_be_viewed: false)
      sign_in(admin)

      patch course_access_company_path(company, company_course.course)

      expect(response).to redirect_to(course_path(company_course.course))
      expect(company_course.reload.can_be_viewed?).to be(true)
    end

    it "redirects when toggling a missing course association" do
      admin = create(:user, role: :admin)
      company = create(:company)
      course = create(:course)
      sign_in(admin)

      patch course_access_company_path(company, course)

      expect(response).to redirect_to(company_path(company))
    end
  end

  describe "company updates" do
    it "updates a company inside the current tenant scope" do
      company = create(:company, name: "Before")
      company_user = make_company_updatable(company)
      sign_in(company_user)

      patch company_path(company), params: {
        company: {
          name: "After",
          fantasy_name: company.fantasy_name,
          cnpj: company.cnpj,
          address: company.address,
          subdomain: company.subdomain
        }
      }

      expect(response).to redirect_to(company_path(company))
      expect(company.reload.name).to eq("After")
    end

    it "renders errors when a company update is invalid" do
      company = create(:company, name: "Before")
      company_user = make_company_updatable(company)
      sign_in(company_user)

      patch company_path(company), params: {
        company: {
          name: "",
          fantasy_name: "",
          cnpj: "",
          address: "",
          subdomain: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(company.reload.name).to eq("Before")
    end
  end
end
