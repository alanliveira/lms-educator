class CourseCompletionService
  def initialize(user:, course:)
    @user = user
    @course = course
  end

  def completed?
    @course.course_classes.exists? &&
      completions.distinct.count(:course_class_id) == @course.course_classes.count
  end

  def completed_at
    completions.maximum(:completed_at)
  end

  def complete!(course_class:)
    CourseClassCompletion.transaction do
      completion = @user.course_class_completions.find_or_initialize_by(course_class:)
      completion.completed_at ||= Time.current
      completion.save!
    end

    issue_certificate! if completed?
    completed?
  end

  def issue_certificate!
    certificate = @course.certificate
    return unless certificate && completed?

    CertificateIssuance.find_or_create_by!(certificate:, course: @course, user: @user) do |issuance|
      issuance.completed_at = completed_at || Time.current
    end
  end

  private

  def completions
    @user.course_class_completions.for_course(@course)
  end
end
