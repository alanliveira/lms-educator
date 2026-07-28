require "rails_helper"

RSpec.describe CompanyCourse, type: :model do
  subject(:company_course) { build(:company_course) }

  it { is_expected.to belong_to(:company) }
  it { is_expected.to belong_to(:course) }

  it "does not allow the same course twice for a company" do
    company_course = create(:company_course)

    duplicate = build(
      :company_course,
      company: company_course.company,
      course: company_course.course
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:course_id]).to be_present
  end
end
