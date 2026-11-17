class WrongDomainMailer < ApplicationMailer
  default from: "See tech <#{ENV.fetch('EMAIL_ADMINISTRATION_SYSTEM')}>"

  def contact_request
    @contact = params[:contact]

    mail to: admin_recipients,
         reply_to: @contact[:email],
         subject: "Contato recebido sem subdomínio"
  end

  private

  def admin_recipients
    admin_company = Company.default
    recipients = admin_company&.users&.with_role(:admin)&.pluck(:email)
    recipients = User.with_role(:admin).pluck(:email) if recipients.blank?
    recipients.presence || [ENV.fetch("EMAIL_ADMINISTRATION_SYSTEM")]
  end
end
