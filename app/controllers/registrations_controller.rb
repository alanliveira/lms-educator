class RegistrationsController < ApplicationController
  skip_before_action :authenticate

  layout 'authentication'

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to sign_in_path, notice: "You need to wait for the approval of the system administrator"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation, :department, :full_name)
  end

  def send_email_verification
    UserMailer.with(user: @user).email_verification.deliver_later
  end
end
