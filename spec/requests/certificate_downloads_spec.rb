require "rails_helper"
require "base64"

RSpec.describe "Certificate downloads", type: :request do
  it "downloads a PDF after all classes are completed" do
    company = create(:company)
    user = create(:user, company: company)
    course = create(:course, workload_hours: 120)
    create(:company_course, company: company, course: course, can_be_viewed: true)
    first_class = create(:course_class, course: course)
    second_class = create(:course_class, course: course)
    certificate = create(:certificate, course: course, description: "{{ nome_do_aluno }} &amp; {{ data_conclucao }} - {{ carga_horaria }}")
    certificate.elements["signatures"][0]["label"] = "Alan Oliveira"
    certificate.save!
    image = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
    certificate.artwork.attach(io: StringIO.new(image), filename: "artwork.png", content_type: "image/png")
    certificate.verification_seal.attach(io: StringIO.new(image), filename: "seal.png", content_type: "image/png")
    completed_at = Time.zone.local(2026, 7, 20, 12)
    create(:course_class_completion, user: user, course_class: first_class, completed_at: completed_at)
    create(:course_class_completion, user: user, course_class: second_class, completed_at: completed_at)
    renderer = CertificatePdfRenderer.new(certificate, user)
    expect(renderer.send(:description)).to include(user.full_name, "&", "120", I18n.l(completed_at.to_date, format: :default))
    expect(renderer.send(:description)).not_to include("&amp;")
    expect(renderer.send(:description_parts).find { |part| part[:text] == user.full_name }[:styles]).to include(:bold)
    sign_in(user)

    get download_course_certificate_path(course)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.body).to start_with("%PDF")
    expect(certificate.reload).to be_valid
    expect(CertificateIssuance.where(user: user, course: course).count).to eq(1)
  end

  it "validates a certificate publicly and renders its PDF from the code" do
    company = create(:company)
    user = create(:user, company: company)
    course = create(:course, workload_hours: 120)
    create(:company_course, company: company, course: course, can_be_viewed: true)
    course_class = create(:course_class, course: course)
    certificate = create(:certificate, course: course)
    issuance = create(:certificate_issuance, certificate: certificate, course: course, user: user, completed_at: Time.zone.local(2026, 7, 20))

    get certificate_validation_path(issuance.verification_code)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Certificado válido", user.full_name, course.name)

    get certificate_validation_path(issuance.verification_code, format: :pdf)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.body).to start_with("%PDF")
  end

  it "redirects when the course has no certificate configured" do
    company = create(:company)
    user = create(:user, company: company)
    course = create(:course)
    create(:company_course, company: company, course: course, can_be_viewed: true)
    create(:course_class, course: course)
    sign_in(user)

    get download_course_certificate_path(course)

    expect(response).to redirect_to(course_path(course))
  end

  it "blocks a download before all classes are completed" do
    company = create(:company)
    user = create(:user, company: company)
    course = create(:course)
    create(:company_course, company: company, course: course, can_be_viewed: true)
    course_class = create(:course_class, course: course)
    create(:certificate, course: course)
    sign_in(user)

    get download_course_certificate_path(course)

    expect(response).to redirect_to(course_course_class_path(course, course_class))
  end

  it "downloads certificates when an optional text element was moved to the library" do
    company = create(:company)
    user = create(:user, company: company)
    course = create(:course)
    create(:company_course, company: company, course: course, can_be_viewed: true)
    course_class = create(:course_class, course: course)
    certificate = create(:certificate, course: course)
    certificate.elements.delete("verification_code")
    certificate.elements["element_library"] = { "verification_code" => Certificate::DEFAULT_ELEMENTS["verification_code"] }
    certificate.save!
    create(:course_class_completion, user: user, course_class: course_class)
    sign_in(user)

    get download_course_certificate_path(course)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
  end
end
