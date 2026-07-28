require "rails_helper"

RSpec.describe "Course classes", type: :request do
  describe "class management" do
    it "renders new, show, and edit screens" do
      admin = create(:user, role: :admin)
      course = create(:course)
      course_class = create(:course_class, course: course)
      sign_in(admin)

      get new_course_course_class_path(course)
      expect(response).to have_http_status(:ok)

      get course_course_class_path(course, course_class)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("h-[calc(100vh-8rem)]")
      expect(response.body).to include("object-contain")
      expect(response.body).to include("data-setup='{\"fill\": true}'")
      expect(response.body).not_to include('width="500"')

      get edit_course_course_class_path(course, course_class)
      expect(response).to have_http_status(:ok)
    end

    it "renders classes for company accounts with access to the course" do
      company = create(:company)
      company_user = create(:user, company: company, role: :company)
      course = create(:course)
      course_class = create(:course_class, course: course)
      create(:company_course, company: company, course: course)
      sign_in(company_user)

      get course_course_class_path(course, course_class)

      expect(response).to have_http_status(:ok)
    end

    it "marks a class as completed and exposes the certificate after the last class" do
      user = create(:user, company: create(:company))
      course = create(:course)
      first_class = create(:course_class, course: course)
      last_class = create(:course_class, course: course)
      create(:company_course, company: user.company, course: course, can_be_viewed: true)
      create(:certificate, course: course)
      sign_in(user)

      post course_complete_course_class_path(course, first_class), as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("completed" => true, "certificate_ready" => false)

      post course_complete_course_class_path(course, last_class), as: :json
      expect(response.parsed_body).to eq("completed" => true, "certificate_ready" => true)
      expect(user.course_class_completions.count).to eq(2)

      get course_course_class_path(course, last_class)
      expect(response.body).to include("Baixar certificado")
    end

    it "does not duplicate a class completion" do
      user = create(:user, company: create(:company))
      course = create(:course)
      course_class = create(:course_class, course: course)
      create(:company_course, company: user.company, course: course, can_be_viewed: true)
      sign_in(user)

      expect do
        2.times { post course_complete_course_class_path(course, course_class), as: :json }
      end.to change(CourseClassCompletion, :count).by(1)
    end

    it "creates a class for a course" do
      admin = create(:user, role: :admin)
      course = create(:course)
      sign_in(admin)

      expect do
        post course_course_classes_path(course), params: {
          course_class: {
            name: "Intro",
            description: "Intro class"
          }
        }
      end.to change(course.course_classes, :count).by(1)

      expect(response).to redirect_to(course_path(course))
    end

    it "renders errors when class creation fails" do
      admin = create(:user, role: :admin)
      course = create(:course)
      sign_in(admin)

      expect do
        post course_course_classes_path(course), params: {
          course_class: {
            name: "",
            description: ""
          }
        }
      end.not_to change(CourseClass, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "updates a class" do
      admin = create(:user, role: :admin)
      course = create(:course)
      course_class = create(:course_class, course: course, name: "Before")
      sign_in(admin)

      patch course_course_class_path(course, course_class), params: {
        course_class: {
          name: "After",
          description: course_class.description
        }
      }

      expect(response).to redirect_to(course_path(course))
      expect(course_class.reload.name).to eq("After")
    end

    it "renders errors when class update fails" do
      admin = create(:user, role: :admin)
      course = create(:course)
      course_class = create(:course_class, course: course)
      sign_in(admin)

      patch course_course_class_path(course, course_class), params: {
        course_class: {
          name: "",
          description: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(course_class.reload.name).not_to eq("")
    end

    it "destroys a class" do
      admin = create(:user, role: :admin)
      course = create(:course)
      course_class = create(:course_class, course: course)
      sign_in(admin)

      expect do
        delete course_course_class_path(course, course_class)
      end.to change { course_class.reload.deleted_at.present? }.from(false).to(true)

      expect(response).to redirect_to(course_path(course))
    end

    it "renders errors when class destroy fails" do
      admin = create(:user, role: :admin)
      course = create(:course)
      course_class = create(:course_class, course: course)
      sign_in(admin)
      allow_any_instance_of(CourseClass).to receive(:destroy).and_return(false)

      delete course_course_class_path(course, course_class)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
