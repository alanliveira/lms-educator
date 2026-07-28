class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :find_company, only: [:new]

  layout 'authentication'

  def new
    return redirect_to sign_in_path, alert: "Acesse pelo subdomínio da empresa para criar uma conta." unless @company

    @user = User.new
    @user.build_company(id: @company.id)
  end

  def create
    return redirect_to sign_in_path, alert: "Acesse pelo subdomínio da empresa para criar uma conta." unless Current.company

    @user = User.new(user_params)
    @company = Current.company
    @user.company = @company

    if @user.save
      UserMailer.with(user: @user).new_user.deliver_later

      redirect_to sign_in_path, notice: "Você precisa da aprovação do administrador da empresa para confirmar o email."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def find_company
    @company = Current.company
  end

  def user_params
    params.require(:user).permit(:email,
                                 :password,
                                 :password_confirmation,
                                 :department,
                                 :full_name)
  end

  def send_email_verification
    UserMailer.with(user: @user).email_verification.deliver_later
  end
end
