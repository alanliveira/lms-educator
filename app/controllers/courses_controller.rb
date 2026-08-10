class CoursesController < ApplicationController
  before_action :set_course, only: %i[show edit update destroy]
  before_action :set_course_permissions

  # GET /courses
  def index
    @courses = policy_scope(Course).with_attached_thumbnail.order(id: :desc).page(params[:page]).per(params[:per])
  end

  # GET /courses/1
  def show
    @course_classes = @course.course_classes.with_attached_thumbnail.page(params[:page]).per(params[:per])
    @course_viewable = CourseVisibilityService.new(course: @course, company: Current.company).viewable?
  end

  # GET /courses/new
  def new
    @course = Course.new
  end

  # GET /courses/1/edit
  def edit; end

  # POST /courses
  def create
    @course = Course.new(course_params)

    if @course.save
      redirect_to @course, notice: "Course was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /courses/1
  def update
    if @course.update(course_params)
      redirect_to @course, notice: "Course was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /courses/1
  def destroy
    @course.destroy!
    redirect_to courses_url, notice: "Course was successfully destroyed.", status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_course
    @course = policy_scope(Course).find(params[:id])
  end

  def set_course_permissions
    @can_manage_courses = Current.user.has_role?(:admin)
    @can_toggle_course_visibility = Current.user.has_role?(:company)
    @course_access_company_id = Current.company&.id
  end

  # Only allow a list of trusted parameters through.
  def course_params
    params.require(:course).permit(:name, :description, :workload_hours, :thumbnail)
  end
end
