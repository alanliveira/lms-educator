require "rails_helper"

RSpec.describe CourseCompletionService do
  it "records a completion once and issues the certificate after the last class" do
    user = create(:user)
    course = create(:course)
    first_class = create(:course_class, course:)
    last_class = create(:course_class, course:)
    certificate = create(:certificate, course:)
    service = described_class.new(user:, course:)

    expect(service.complete!(course_class: first_class)).to be(false)
    expect { service.complete!(course_class: first_class) }.not_to change(CourseClassCompletion, :count)
    expect(service.complete!(course_class: last_class)).to be(true)
    expect(CertificateIssuance.find_by(certificate:, course:, user:)).to be_present
  end
end
