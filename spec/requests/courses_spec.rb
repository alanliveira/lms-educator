require "rails_helper"

RSpec.describe "Courses", type: :request do
  describe "GET /courses" do
    it "lists courses for admins" do
      admin = create(:user, role: :admin)
      course = create(:course)

      sign_in(admin)
      get courses_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(course.name)
    end

    it "paginates the course listing" do
      admin = create(:user, role: :admin)
      first_course = create(:course, name: "First Course")
      second_course = create(:course, name: "Second Course")

      sign_in(admin)
      get courses_path, params: { page: 2, per: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(first_course.name)
      expect(response.body).not_to include(second_course.name)
    end

    it "lists only viewable company courses for students" do
      company = create(:company)
      student = create(:user, company: company, role: :student)
      visible_course = create(:course, name: "Visible Course")
      hidden_course = create(:course, name: "Hidden Course")
      create(:company_course, company: company, course: visible_course, can_be_viewed: true)
      create(:company_course, company: company, course: hidden_course, can_be_viewed: false)

      sign_in(student)
      get courses_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Visible Course")
      expect(response.body).not_to include("Hidden Course")
    end

    it "lists company courses for company accounts" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      course = create(:course, name: "Company Course")
      create(:company_course, company: company, course: course)

      sign_in(company_user)
      get courses_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Company Course")
    end
  end

  describe "course management" do
    it "renders new, show, and edit screens" do
      admin = create(:user, role: :admin)
      course = create(:course)
      sign_in(admin)

      get new_course_path
      expect(response).to have_http_status(:ok)

      get course_path(course)
      expect(response).to have_http_status(:ok)

      get edit_course_path(course)
      expect(response).to have_http_status(:ok)
    end

    it "shows company courses for company accounts" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      course = create(:course)
      create(:company_course, company: company, course: course)
      sign_in(company_user)

      get course_path(course)

      expect(response).to have_http_status(:ok)
    end

    it "creates a course" do
      admin = create(:user, role: :admin)
      sign_in(admin)

      expect do
        post courses_path, params: {
          course: {
            name: "Ruby Fundamentals",
            description: "A focused Ruby course",
            workload_hours: 120
          }
        }
      end.to change(Course, :count).by(1)

      expect(response).to redirect_to(course_path(Course.last))
      expect(Course.last.workload_hours).to eq(120)
    end

    it "renders errors when course creation fails" do
      admin = create(:user, role: :admin)
      sign_in(admin)

      expect do
        post courses_path, params: {
          course: {
            name: "",
            description: ""
          }
        }
      end.not_to change(Course, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "updates a course" do
      admin = create(:user, role: :admin)
      course = create(:course, name: "Old Name")
      sign_in(admin)

      patch course_path(course), params: {
        course: {
          name: "New Name",
          description: course.description
        }
      }

      expect(response).to redirect_to(course_path(course))
      expect(course.reload.name).to eq("New Name")
    end

    it "renders errors when course update fails" do
      admin = create(:user, role: :admin)
      course = create(:course)
      sign_in(admin)

      patch course_path(course), params: {
        course: {
          name: "",
          description: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(course.reload.name).not_to eq("")
    end

    it "destroys a course" do
      admin = create(:user, role: :admin)
      course = create(:course)
      sign_in(admin)

      expect do
        delete course_path(course)
      end.to change { Course.with_deleted.count }.by(0)
        .and change { course.reload.deleted_at.present? }.from(false).to(true)

      expect(response).to redirect_to(courses_path)
    end
  end
end
