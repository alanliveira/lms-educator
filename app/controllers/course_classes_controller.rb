class CourseClassesController < ApplicationController
  before_action :find_course
  before_action :find_course_class, except: [:new, :create]

  def show
    @certificate = @course.certificate
    @course_completed = CourseClassCompletion.course_completed?(Current.user, @course)
  end

  def complete
    completion = Current.user.course_class_completions.find_or_initialize_by(course_class: @course_class)
    completion.completed_at ||= Time.current
    completion.save!

    certificate_ready = CourseClassCompletion.course_completed?(Current.user, @course)
    CourseClassCompletion.issue_certificate_for!(Current.user, @course) if certificate_ready
    render json: { completed: true, certificate_ready: certificate_ready }
  end

  def new
    @course_class = @course.course_classes.build
  end

  def edit; end

  def create
    @course_class = @course.course_classes.build(course_class_params)
    if @course_class.save
      flash[:notice] = "Aula criada com sucesso"
      redirect_to @course
    else
      flash[:alert] = "Erro ao criar aula"
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @course_class.update(course_class_params)
      flash[:notice] = "Aula atualizada com sucesso"
      redirect_to @course
    else
      flash[:alert] = "Erro ao atualizar a aula"
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @course_class.destroy
      flash[:notice] = "Aula apagada com sucesso"
      redirect_to course_path(@course)
    else
      flash[:alert] = "Erro ao apagar a aula"
      render :show, status: :unprocessable_content
    end
  end

  private

  def find_course
    @course = policy_scope(Course).find(params[:course_id])
  end

  def find_course_class
    @course_class = @course.course_classes.find(params[:id] || params[:course_class_id])
  end

  def course_class_params
    params.require(:course_class).permit(:name, :description, :thumbnail, :video, :attachments)
  end

end
