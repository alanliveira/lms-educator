class UsersController < ApplicationController
  before_action :find_user, only: [:status, :show, :edit, :update]

  def index
    @users = if Current.user.has_role?(:admin)
               User.order(id: :desc).page(params[:page]).per(params[:per])
             else
               Current.user.company.users.order(id: :desc) # .page(params[:page]).per(params[:per])
             end
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
    @user.company_user = CompanyUser.new
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

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_user
    @user = User.includes(:company_user).where(id: params[:id]).first
  end

  def user_params
    params.require(:user).permit(:email,
                                 :password,
                                 :department,
                                 :full_name,
                                 :active,
                                 company_user_attributes: [:company_id])
  end
end
