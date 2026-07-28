class SetupController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_if_setup_complete, only: :new

  layout "authentication"

  def new
    build_setup_records
  end

  def create
    build_setup_records
    @company.assign_attributes(company_params.merge(subdomain: "admin"))
    @owner.assign_attributes(user_params.merge(active: true, verified: true))
    @company.users << @owner

    if @company.save
      @company.company_users.find_by!(user: @owner).update!(owner: true)
      @owner.remove_role(:student)
      @owner.add_role(:admin)
      redirect_to sign_in_path, notice: "Empresa e usuário administrador criados com sucesso."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def redirect_if_setup_complete
    redirect_to sign_in_path unless initial_setup_required?
  end

  def build_setup_records
    @company = Company.new(subdomain: "admin")
    @owner = User.new
  end

  def company_params
    params.require(:company).permit(:name, :fantasy_name, :cnpj, :address, :logo)
  end

  def user_params
    params.require(:user).permit(:full_name, :department, :email, :password, :password_confirmation)
  end
end
