class UsersController < ApplicationController
  before_action :find_user, only: [:status, :show, :edit, :update, :destroy]

  def index
    @users = if Current.user.has_role?(:admin)
               User.order(id: :desc).page(params[:page]).per(params[:per])
             else
               policy_scope(User).order(id: :desc).page(params[:page]).per(params[:per])
             end
  end

  def show; end

  def status
    @user.toggle(:active)

    if @user.save
      flash[:notice] = 'Status do usuário alterado com sucesso!'
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path) }
      end
    else
      @users = policy_scope(User).order(id: :desc).page(params[:page]).per(params[:per])
      render :index, status: :unprocessable_content
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
      redirect_to @user, notice: "Usuário criado com sucesso"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "Usuário alterado com sucesso"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @user.destroy!
    redirect_to users_url, notice: "Usuário excluido do sistema."
  end

  private

  def find_user
    @user = policy_scope(User).includes(:company_user).find(params[:id])
  end

  def user_params
    permitted_params = [:email, :password, :department, :full_name]
    permitted_params << :active if Current.user.has_role?(:admin)

    if Current.user.has_role?(:admin)
      params.require(:user).permit(*permitted_params, company_user_attributes: [:company_id])
    else
      params.require(:user).permit(*permitted_params)
    end
  end

end
