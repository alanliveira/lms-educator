class CourseClassCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :course_class

  validates :completed_at, presence: true
  validates :course_class_id, uniqueness: { scope: :user_id }

  scope :for_course, ->(course) { joins(:course_class).where(course_classes: { course_id: course.id }) }

  def self.course_completed?(user, course)
    course.course_classes.exists? &&
      where(user: user).for_course(course).distinct.count(:course_class_id) == course.course_classes.count
  end

  def self.completed_at_for(user, course)
    where(user: user).for_course(course).maximum(:completed_at)
  end

  def self.issue_certificate_for!(user, course)
    certificate = course.certificate
    return unless certificate && course_completed?(user, course)

    CertificateIssuance.find_or_create_by!(certificate: certificate, course: course, user: user) do |issuance|
      issuance.completed_at = completed_at_for(user, course) || Time.current
    end
  end
end
