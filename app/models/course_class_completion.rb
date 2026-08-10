class CourseClassCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :course_class

  validates :completed_at, presence: true
  validates :course_class_id, uniqueness: { scope: :user_id }

  scope :for_course, ->(course) { joins(:course_class).where(course_classes: { course_id: course.id }) }
end
