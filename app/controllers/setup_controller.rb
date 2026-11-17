class SetupController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_if_setup_complete, only: :new

  layout "authentication"

  def new
    build_setup_records
  end

  def create
    creation = Setup::CreateService.new(company_attributes: company_params, owner_attributes: user_params)
    @company = creation.company
    @owner = creation.owner

    if creation.call
      # The setup only runs on the `admin` subdomain (enforced by
      # ApplicationController#redirect_to_initial_setup), so this redirect stays
      # on the same host and Turbo can follow it.
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
    @company = Company.new(subdomain: Company::DEFAULT_SUBDOMAIN)
    @owner = User.new
  end

  def company_params
    params.require(:company).permit(:name, :fantasy_name, :cnpj, :address, :logo)
  end

  def user_params
    params.require(:user).permit(:full_name, :department, :email, :password, :password_confirmation)
  end
end
