require "rails_helper"

RSpec.describe CourseVisibilityService do
  it "returns true only when the company has course visibility" do
    course = create(:course)
    company = create(:company)
    create(:company_course, course:, company:, can_be_viewed: false)

    service = described_class.new(course:, company:)

    expect(service.viewable?).to be(false)

    company.company_courses.find_by!(course:).update!(can_be_viewed: true)
    expect(service.viewable?).to be(true)
  end
end
