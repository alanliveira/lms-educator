class Identity::EmailVerificationsController < ApplicationController
  skip_before_action :authenticate, only: :show
  before_action :set_user, only: :show

  layout 'authentication'

  def show
    @user.update! verified: true
    redirect_to root_path(params: { company: { identifier: params.dig('company', 'identifier') } }),
                notice: "Obrigado pela confirmação do seu endereço de email"
  end

  def create
    send_email_verification
    redirect_to root_path, notice: "Enviamos as instruções de verificação da conta para o seu email"
  end

  private

  def set_user
    @user = User.find_by_token_for!(:email_verification, params[:sid])
  rescue StandardError
    redirect_to edit_identity_email_path, alert: "O endereço de validação de email está inválido"
  end

  def send_email_verification
    UserMailer.with(user: Current.user).email_verification.deliver_later
  end
end
