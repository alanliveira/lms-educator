class RegistrationsController < ApplicationController
  skip_before_action :authenticate
  before_action :find_company, only: [:new]

  layout 'authentication'

  def new
    @user = User.new
    @user.build_company(id: @company.id)
  end

  def create
    @user = User.new(user_params)
    @company = Company.find_by(id: params.dig(:user, :company_attributes, :id))
    @user.company = @company

    if @user.save
      redirect_to sign_in_path(params: { company: { identifier: @company.identifier } }), notice: "Você precisa da aprovação do administrador da empresa para confirmar o emial"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def find_company
    @company = Company.find_by(identifier: params.dig(:company, :identifier))
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
