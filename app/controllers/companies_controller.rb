class CompaniesController < ApplicationController
  before_action :set_company, only: %i[show edit update destroy add_course remove_course toggle_access]
  before_action :set_company_permissions

  # GET /companies
  def index
    @companies = Company.includes(:owner).order(id: :desc).page(params[:page]).per(params[:per])
  end

  # GET /companies/1
  def show
    @company_courses = @company.courses.with_attached_thumbnail
    @available_courses = Course.where.not(id: @company_courses.select(:id))
    @company_course = @company.company_courses.build
  end

  # GET /companies/new
  def new
    @company = Company.new
    @company.users.build(active: true)
    prepare_company_form
  end

  # GET /companies/1/edit
  def edit
    prepare_company_form
  end

  # POST /companies
  def create
    creation = Companies::CreateService.new(attributes: company_params)
    @company = creation.company

    if creation.call
      redirect_to @company, notice: "Empresa criada com sucesso."
    else
      prepare_company_form
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /companies/1
  def update
    if @company.update(company_params)
      redirect_to @company, notice: "Empresa atualizada com sucesso.", status: :see_other
    else
      prepare_company_form
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
      prepare_show_data
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
      company_course.update!(can_be_viewed: !company_course.can_be_viewed?)
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

  def set_company_permissions
    @can_manage_company = Current.user.has_role?(:admin)
  end

  def prepare_show_data
    @company_courses = @company.courses.with_attached_thumbnail
    @available_courses = Course.where.not(id: @company_courses.select(:id))
    @company_course = @company.company_courses.build
  end

  def prepare_company_form
    @company_owner_user_ids = @company.users.select { |user| user.has_role?(:company) }.map(&:id)
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
