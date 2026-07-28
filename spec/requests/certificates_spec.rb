require "rails_helper"

RSpec.describe "Certificates", type: :request do
  describe "GET /courses/:course_id/certificate/edit" do
    it "renders the certificate editor for admins" do
      admin = create(:user, role: :admin)
      course = create(:course)
      certificate = create(:certificate, course: course)
      certificate.verification_seal.attach(
        io: StringIO.new("fake seal"),
        filename: "seal.png",
        content_type: "image/png"
      )
      sign_in(admin)

      get edit_course_certificate_path(course)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Editar certificado")
      expect(response.body).to include("Arte do certificado")
      expect(response.body).to include("Selo de verificação")
      expect(response.body).to include("Transparência da arte")
      expect(response.body).to include("Campos do descritivo")
      expect(response.body).to include("Data de conclusão")
      expect(response.body).to include("Alinhamento horizontal")
      expect(response.body).to include("Alinhamento vertical")
      expect(response.body).to include("Propriedades:")
      expect(response.body).to include("Adicionar assinatura")
      expect(response.body).to include("Biblioteca")
      expect(response.body).to include("xl:grid-cols-[16rem_minmax(0,1fr)_20rem]")
      expect(response.body).to include("overflow-y-auto")
    end
  end

  describe "PATCH /courses/:course_id/certificate" do
    it "creates and stores the certificate editor configuration" do
      admin = create(:user, role: :admin)
      course = create(:course)
      sign_in(admin)

      patch course_certificate_path(course), params: {
        certificate: {
          description: "Certificamos que {{ nome_do_aluno }} em {{ data_conclusao }}, concluiu o curso {{ titulo_curso }} com carga horária de {{ carga_horaria }} horas.",
          total_hours: 80,
          elements_json: {
            background_opacity: 0.4,
            description: { x: 20, y: 30, width: 80, height: 18, font_family: "Georgia", font_size: 24, color: "#ff0000", text_align: "right", vertical_align: "top" },
            qr_code: { x: 80, y: 20, width: 16, height: 16 },
            element_library: { verification_seal: { x: 88, y: 14, width: 12, height: 14 } },
            signature_library: [{ id: "signature-removed", label: "Removed", x: 50, y: 90 }],
            total_hours: { x: 20, y: 20 },
            verification_code: { x: 20, y: 80 },
            signatures: [
              { id: "signature-1", label: "Director", x: 20, y: 88 },
              { id: "signature-2", label: "Instructor", x: 80, y: 88 }
            ]
          }.to_json
        }
      }

      expect(response).to redirect_to(edit_course_certificate_path(course))
      expect(course.reload.certificate.total_hours).to eq(80)
      expect(course.certificate.elements.fetch("background_opacity")).to eq(0.4)
      expect(course.certificate.elements.dig("description", "font_family")).to eq("Georgia")
      expect(course.certificate.elements.dig("description", "text_align")).to eq("right")
      expect(course.certificate.elements.dig("description", "vertical_align")).to eq("top")
      expect(course.certificate.elements).not_to have_key("total_hours")
      expect(course.certificate.elements.dig("qr_code", "width")).to eq(16.0)
      expect(course.certificate.elements.dig("element_library", "verification_seal", "width")).to eq(12.0)
      expect(course.certificate.elements.fetch("signature_library").size).to eq(1)
      expect(course.certificate.description).to include("{{ nome_do_aluno }}")
      expect(course.certificate.description).to include("{{ carga_horaria }}")
      expect(course.certificate.elements.fetch("signatures").size).to eq(2)
    end

    it "falls back to the default layout when the elements JSON is invalid" do
      admin = create(:user, role: :admin)
      course = create(:course)
      sign_in(admin)

      patch course_certificate_path(course), params: {
        certificate: {
          total_hours: 20,
          elements_json: "{invalid"
        }
      }

      expect(response).to redirect_to(edit_course_certificate_path(course))
      expect(course.reload.certificate.elements).to eq(Certificate::DEFAULT_ELEMENTS)
    end

    it "renders the editor when certificate settings are invalid" do
      admin = create(:user, role: :admin)
      course = create(:course)
      sign_in(admin)

      patch course_certificate_path(course), params: {
        certificate: {
          total_hours: -1,
          elements_json: {}.to_json
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not allow non-admin users to edit the certificate" do
      company = create(:company)
      user = create(:user, company: company, role: :student)
      course = create(:course)
      sign_in(user)

      get edit_course_certificate_path(course)

      expect(response).to redirect_to(root_path)
      expect(course.reload.certificate).to be_nil
    end
  end
end
