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
    @company_subdomain = @user&.company&.subdomain || Company.find(ENV.fetch('COMPANY_DEFAULT_ID').to_i).subdomain
    @company_host = company_host(@company_subdomain)
    
    mail to: @user.email, subject: "Valide o seu email"
  end
  
  def new_user
    @user = params[:user]
    @company_subdomain = @user&.company&.subdomain || Company.find(ENV.fetch('COMPANY_DEFAULT_ID').to_i).subdomain
    @owner_user = @user&.company&.owner || Company.find(ENV.fetch('COMPANY_DEFAULT_ID').to_i).owner

    mail to: @owner_user.email, subject: "Cadastro de novo funcionário"
  end

  private

  def company_host(subdomain)
    [subdomain, ENV.fetch("EMAIL_HOST")].compact_blank.join(".")
  end
end
