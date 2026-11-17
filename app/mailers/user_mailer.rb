class UserMailer < ApplicationMailer
  # this domain must be verified with Resend
  default from: "See tech <#{ENV.fetch('EMAIL_ADMINISTRATION_SYSTEM')}>",
          host: 'https://aprenda.seetech.com.br'

  def password_reset
    @user = params[:user]
    @signed_id = @user.generate_token_for(:password_reset)

    mail to: @user.email, subject: "Resetar a sua senha"
  end

  def email_verification
    @user = params[:user]
    @signed_id = @user.generate_token_for(:email_verification)
    @company_subdomain = company_for(@user)&.subdomain
    @company_host = company_host(@company_subdomain)

    mail to: @user.email, subject: "Valide o seu email"
  end

  def new_user
    @user = params[:user]
    company = company_for(@user)
    @company_subdomain = company&.subdomain
    @owner_user = company&.owner
    return if @owner_user.blank?

    mail to: @owner_user.email, subject: "Cadastro de novo funcionário"
  end

  private

  # The user's own company, falling back to the company created by the
  # initial setup (Company.default) — no environment variable involved.
  def company_for(user)
    user&.company || Company.default
  end

  def company_host(subdomain)
    [subdomain, ENV.fetch("EMAIL_HOST")].compact_blank.join(".")
  end
end
