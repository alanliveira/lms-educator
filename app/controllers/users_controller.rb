class UsersController < ApplicationController
  before_action :find_user, only: [:status, :show, :edit, :update, :destroy]

  def index
    load_users(Current.user.has_role?(:admin) ? User.all : policy_scope(User))
  end

  def show
    @user_role_label = user_role_label_for(@user)
    @can_manage_displayed_user = can_manage_user?
    @can_destroy_displayed_user = @can_manage_displayed_user && !@user.owner?
  end

  def status
    return deny_user_management unless can_manage_user?

    @user.toggle(:active)

    if @user.save
      flash[:notice] = 'Status do usuário alterado com sucesso!'
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path) }
      end
    else
      load_users(policy_scope(User))
      render :index, status: :unprocessable_content
    end
  end

  def new
    @user = User.new(active: true)
    @user.company_user = CompanyUser.new
    prepare_user_form
  end

  def create
    @user = User.new(user_params)
    @user.active = true

    if @user.save
      redirect_to @user, notice: "Usuário criado com sucesso"
    else
      prepare_user_form
      render :new, status: :unprocessable_content
    end
  end

  def edit
    return deny_user_management unless can_manage_user?

    @user.build_company_user if Current.user.has_role?(:admin) && @user.company_user.nil?
    prepare_user_form
  end

  def update
    return deny_user_management unless can_manage_user?

    update_service = Users::UpdateService.new(user: @user, actor: Current.user, attributes: user_params)
    return deny_role_change unless update_service.role_change_allowed?

    if update_service.call
      redirect_to @user, notice: "Usuário alterado com sucesso"
    else
      @user.build_company_user if Current.user.has_role?(:admin) && @user.company_user.nil?
      prepare_user_form
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    return deny_user_management unless can_manage_user?

    @user.destroy!
    redirect_to users_url, notice: "Usuário excluido do sistema."
  end

  private

  def load_users(scope)
    @users = scope.includes(:roles).order(id: :desc).page(params[:page]).per(params[:per])

    non_admin_users = @users.to_a.reject { |user| user.has_cached_role?(:admin) }
    return if non_admin_users.empty?

    ActiveRecord::Associations::Preloader.new(
      records: non_admin_users,
      associations: [:company_user, :company]
    ).call
  end

  def find_user
    @user = policy_scope(User).includes(:company_user).find(params[:id])
  end

  def prepare_user_form
    current_user_is_admin = Current.user.has_role?(:admin)
    current_user_is_company = Current.user.has_role?(:company)

    @user_form_options = {
      current_role: role_for(@user),
      show_admin_role: current_user_is_admin && @user.persisted?,
      allow_admin_role_change: current_user_is_admin && @user != Current.user,
      show_company_role: current_user_is_company && @user.has_role?(:student),
      show_company_selector: current_user_is_admin && (@user.new_record? || @user != Current.user),
      companies: current_user_is_admin ? Company.order(:fantasy_name) : []
    }
  end

  def role_for(user)
    Users::UpdateService::ROLES.find { |role| user.has_role?(role) }
  end

  def user_role_label_for(user)
    label = { "admin" => "Administrador", "company" => "Empresa", "student" => "Colaborador" }.fetch(role_for(user), "Sem role")
    user.owner? ? "#{label} - Proprietário" : label
  end

  def user_params
    permitted_params = [:email, :password, :department, :full_name]
    permitted_params << :active if Current.user.has_role?(:admin) || Current.user.has_role?(:company)

    if Current.user.has_role?(:admin)
      params.require(:user).permit(*permitted_params, :role, company_user_attributes: [:id, :company_id])
    elsif Current.user.has_role?(:company)
      params.require(:user).permit(*permitted_params, :role)
    else
      params.require(:user).permit(*permitted_params)
    end
  end

  def can_manage_user?
    return true if Current.user.has_role?(:admin)

    Current.user.has_role?(:company) && Current.user.company.present? && @user.has_role?(:student) && @user.company == Current.user.company
  end

  def deny_user_management
    redirect_to users_path, alert: "Você não tem permissão para alterar este usuário."
  end

  def deny_role_change
    redirect_to edit_user_path(@user), alert: "Você não tem permissão para alterar este role."
  end
end
