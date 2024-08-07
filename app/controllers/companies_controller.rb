class CompaniesController < ApplicationController
  before_action :set_company, only: %i[show edit update destroy]

  # GET /companies
  def index
    @companies = Company.order(id: :desc).page(params[:page]).per(params[:per])
  end

  # GET /companies/1
  def show; end

  # GET /companies/new
  def new
    @company = Company.new
    @company.users.build(active: true)
  end

  # GET /companies/1/edit
  def edit; end

  # POST /companies
  def create
    @company = Company.new(company_params)
    @company.users.first.active = true
    @company.users.first.remove_role(:student)
    @company.users.first.add_role(:company)

    if @company.save
      @company.company_users.first.update(owner: true)

      redirect_to @company, notice: "Company was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /companies/1
  def update
    if @company.update(company_params)
      redirect_to @company, notice: "Company was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /companies/1
  def destroy
    @company.destroy!
    redirect_to companies_url, notice: "Company was successfully destroyed.", status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_company
    @company = Company.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def company_params
    params.require(:company)
          .permit(:name,
                  :fantasy_name,
                  :cnpj,
                  :logo,
                  :address,
                  :identifier,
                  users_attributes: [:full_name,
                                     :department,
                                     :email,
                                     :password,
                                     :active])
  end
end
