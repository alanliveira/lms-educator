class CourseClassesController < ApplicationController
  before_action :find_course
  before_action :find_course_class, except: [:new, :create]
  before_action :set_course_class_permissions

  def show
    @certificate = @course.certificate
    @course_completed = course_completion.completed?
    @course_classes = @course.course_classes.with_attached_thumbnail
  end

  def complete
    certificate_ready = course_completion.complete!(course_class: @course_class)
    render json: { completed: true, certificate_ready: }
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
    params.require(:course_class).permit(:name, :description, :thumbnail, :video, attachments: [])
  end

  def course_completion
    @course_completion ||= CourseCompletionService.new(user: Current.user, course: @course)
  end

  def set_course_class_permissions
    @can_manage_course_classes = Current.user.has_role?(:admin)
  end
end
