class CourseClassesController < ApplicationController
  before_action :find_course
  before_action :find_course_class, except: [:new, :create]

  def show; end

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
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @course_class.update(course_class_params)
      flash[:notice] = "Aula atualizada com sucesso"
      redirect_to @course
    else
      flash[:alert] = "Erro ao atualizar a aula"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @course_class.destroy
      flash[:notice] = "Aula apagada com sucesso"
      redirect_to course_path(@course)
    else
      flash[:alert] = "Erro ao apagar a aula"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def find_course
    @course = Course.find(params[:course_id])
  end

  def find_course_class
    @course_class = @course.course_classes.find(params[:id])
  end

  def course_class_params
    params.require(:course_class).permit(:name, :description, :thumbnail, :video, :attachments)
  end
end
