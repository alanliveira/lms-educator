require Rails.root.join("app/services/certificate_pdf_renderer")

class CertificatesController < ApplicationController
  before_action :require_admin, only: %i[edit update]
  before_action :set_course
  before_action :set_certificate

  def edit; end

  def download
    unless @certificate.persisted?
      redirect_to course_path(@course), alert: "Este curso ainda não possui um certificado configurado."
      return
    end

    completion = CourseCompletionService.new(user: Current.user, course: @course)

    unless completion.completed?
      redirect_to course_course_class_path(@course, @course.course_classes.first),
                  alert: "Conclua todas as aulas para baixar o certificado."
      return
    end

    issuance = completion.issue_certificate!
    send_data CertificatePdfRenderer.new(
      @certificate,
      Current.user,
      verification_url: certificate_validation_url(issuance.verification_code)
    ).render,
              filename: "certificado-#{@course.name.parameterize}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def update
    @certificate.assign_attributes(certificate_params)
    @certificate.elements = CertificateElementsNormalizer.call(params.dig(:certificate, :elements_json))

    if @certificate.save
      redirect_to edit_course_certificate_path(@course), notice: "Certificado atualizado com sucesso."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def require_admin
    return if Current.user&.has_role?(:admin)

    redirect_back_or_to root_path, alert: "Você não tem permissão para editar certificados."
  end

  def set_course
    @course = policy_scope(Course).find(params[:course_id])
  end

  def set_certificate
    @certificate = @course.certificate || @course.build_certificate
  end

  def certificate_params
    params.require(:certificate).permit(:description, :total_hours, :artwork, :verification_seal)
  end
end
