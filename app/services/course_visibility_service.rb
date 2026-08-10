class CourseVisibilityService
  def initialize(course:, company:)
    @course = course
    @company = company
  end

  def viewable?
    return false unless @company

    @course.company_courses.exists?(company: @company, can_be_viewed: true)
  end
end
