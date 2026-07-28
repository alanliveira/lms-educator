class CertificateValidationsController < ApplicationController
  allow_unauthenticated_access

  def show
    @issuance = CertificateIssuance.includes(:certificate, :course, :user).find_by(verification_code: params[:verification_code].to_s.upcase)
    return render :invalid, status: :not_found unless @issuance

    return send_certificate_pdf if request.format.pdf?

    @certificate_url = certificate_validation_path(@issuance.verification_code, format: :pdf)
  end

  private

  def send_certificate_pdf
    send_data CertificatePdfRenderer.new(
      @issuance.certificate,
      @issuance.user,
      verification_url: certificate_validation_url(@issuance.verification_code)
    ).render,
              filename: "certificado-#{@issuance.course.name.parameterize}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end
end
