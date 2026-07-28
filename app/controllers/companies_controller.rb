class CompaniesController < ApplicationController
  before_action :set_company, only: %i[show edit update destroy add_course remove_course toggle_access]

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

      redirect_to @company, notice: "Empresa criada com sucesso."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /companies/1
  def update
    if @company.update(company_params)
      redirect_to @company, notice: "Empresa atualizada com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /companies/1
  def destroy
    @company.destroy!
    redirect_to companies_url, notice: "Empresa removida com sucesso.", status: :see_other
  end

  def add_course
    if @company.update(company_params)
      redirect_to company_path(@company), notice: 'Curso adicionado para a empresa com sucesso'
    else
      render :show, status: :unprocessable_content, alert: 'Erro ao adicionar o curso para a empresa'
    end
  end

  def remove_course
    @company_course = @company.company_courses.find_by(course_id: params[:course_id])

    if @company_course&.destroy
      redirect_to company_path(@company), notice: "Curso removido da empresa com sucesso"
    else
      render :show, status: :unprocessable_content, alert: 'Curso não encontrado ou já foi removido.'
    end
  end

  def toggle_access
    company_course = @company.company_courses.find_by(course_id: params[:course_id])
    if company_course
      company_course.toggle!(:can_be_viewed)
      redirect_to course_path(company_course.course), notice: 'O acesso ao curso foi atualizado com sucesso.'
    else
      redirect_to company_path(@company), alert: 'Associação entre empresa e curso não encontrada.'
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_company
    @company = policy_scope(Company).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def company_params
    params.require(:company).permit(:name,
                                    :fantasy_name,
                                    :cnpj,
                                    :logo,
                                    :address,
                                    :subdomain,
                                    users_attributes: [:full_name,
                                                       :department,
                                                       :email,
                                                       :password,
                                                       :active],
                                    company_courses_attributes: [:course_id,
                                                                 :_destroy])
  end
end
