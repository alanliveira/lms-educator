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
      flash[:notice] = "CourseClass successfully created"
      redirect_to @course
    else
      flash[:alert] = "Something went wrong"
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @course_class.update(course_class_params)
      flash[:success] = "CourseClass was successfully updated"
      redirect_to @course
    else
      flash[:error] = "Something went wrong"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @course_class.destroy
      flash[:success] = "CourseClass was successfully deleted"
      redirect_to course_class_path
    else
      flash[:error] = "Something went wrong"
      redirect_to course_class_path
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
