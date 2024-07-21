class UserMailer < ApplicationMailer
  # this domain must be verified with Resend
  default from: "Message plataform <#{ENV.fetch('EMAIL_ADMINISTRATION_SYSTEM')}>"

  def password_reset
    @user = params[:user]
    @signed_id = @user.generate_token_for(:password_reset)

    mail to: @user.email, subject: "Reset your password"
  end

  def email_verification
    @user = params[:user]
    @signed_id = @user.generate_token_for(:email_verification)

    mail to: @user.email, subject: "Verify your email"
  end

end
