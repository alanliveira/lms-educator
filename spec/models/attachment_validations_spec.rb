require "rails_helper"

RSpec.describe "Attachment validations", type: :model do
  def attach_file(record, attachment, content_type:)
    record.public_send(attachment).attach(
      io: StringIO.new("file content"),
      filename: "file",
      content_type: content_type
    )
  end

  it "rejects a non-image company logo" do
    company = build(:company)
    attach_file(company, :logo, content_type: "application/pdf")

    company.validate

    expect(company.errors.of_kind?(:logo, :content_type_invalid)).to be(true)
  end

  it "rejects a non-image course thumbnail" do
    course = build(:course)
    attach_file(course, :thumbnail, content_type: "application/pdf")

    course.validate

    expect(course.errors.of_kind?(:thumbnail, :content_type_invalid)).to be(true)
  end

  it "rejects unsupported course class video and attachments" do
    course_class = build(:course_class)
    attach_file(course_class, :video, content_type: "video/webm")
    attach_file(course_class, :attachments, content_type: "application/zip")

    course_class.validate

    expect(course_class.errors.of_kind?(:video, :content_type_invalid)).to be(true)
    expect(course_class.errors.of_kind?(:attachments, :content_type_invalid)).to be(true)
  end

  it "rejects unsupported certificate artwork and seal" do
    certificate = build(:certificate)
    attach_file(certificate, :artwork, content_type: "image/webp")
    attach_file(certificate, :verification_seal, content_type: "image/webp")

    certificate.validate

    expect(certificate.errors.of_kind?(:artwork, :content_type_invalid)).to be(true)
    expect(certificate.errors.of_kind?(:verification_seal, :content_type_invalid)).to be(true)
  end
end
