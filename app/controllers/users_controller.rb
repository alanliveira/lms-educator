class UsersController < ApplicationController
  before_action :find_user, only: [:status, :show]

  def index
    @users = User.order(id: :desc).page(params[:page]).per(params[:per])
  end

  def show; end

  def status
    @user.toggle(:active)

    if @user.save
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def new
    @user = User.new(active: true)
    @user.company_users.build
  end

  def create
    @user = User.new(user_params)
    @user.active = true

    if @user.save
      redirect_to @user, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def find_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email,
                                 :password,
                                 :department,
                                 :full_name,
                                 :active,
                                 company_users_attributes: [:company_id])
  end
end
