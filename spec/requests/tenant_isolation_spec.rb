require "rails_helper"

RSpec.describe "Tenant isolation", type: :request do
  before do
    @company_a = create(:company, name: "Company A", subdomain: "company-a")
    @company_b = create(:company, name: "Company B", subdomain: "company-b")

    @company_user = create(:user, company: @company_a, role: :company, email: "owner-a@example.test")
    @student_a = create(:user, company: @company_a, role: :student, email: "student-a@example.test")
    @student_b = create(:user, company: @company_b, role: :student, active: false, email: "student-b@example.test")

    @course_a = create(:course, name: "Course A")
    create(:company_course, company: @company_a, course: @course_a, can_be_viewed: true)
    @course_b = create(:course, name: "Course B")
    create(:company_course, company: @company_b, course: @course_b, can_be_viewed: true)
    @course_class_b = create(:course_class, course: @course_b, name: "Class B")
  end

  it "prevents a company user from viewing a user from another company" do
    sign_in(@company_user)

    get user_path(@student_b)

    expect_tenant_boundary_response
  end

  it "prevents a company user from updating a user from another company" do
    sign_in(@company_user)

    expect do
      patch user_path(@student_b), params: {
        user: {
          full_name: "Compromised Name",
          department: @student_b.department,
          email: @student_b.email
        }
      }
    end.not_to change { @student_b.reload.full_name }

    expect_tenant_boundary_response
  end

  it "prevents a company user from activating a user from another company" do
    sign_in(@company_user)

    expect do
      get status_user_path(@student_b)
    end.not_to change { @student_b.reload.active? }

    expect_tenant_boundary_response
  end

  it "prevents a student from viewing a class from another company course" do
    sign_in(@student_a)

    get course_course_class_path(@course_b, @course_class_b)

    expect_tenant_boundary_response
  end

  it "prevents a company user from toggling course access for another company" do
    company_b_course = @company_b.company_courses.find_by!(course: @course_b)
    sign_in(@company_user)

    expect do
      patch course_access_company_path(@company_b, course_id: @course_b.id)
    end.not_to change { company_b_course.reload.can_be_viewed? }

    expect_tenant_boundary_response
  end

  def expect_tenant_boundary_response
    expect(response.status).to be_in([403, 404, 302])
    expect(response).not_to have_http_status(:success)
  end
end
