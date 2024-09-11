class Course < ApplicationRecord
  acts_as_paranoid

  has_many :course_classes, dependent: :destroy

  has_one_attached :thumbnail

  has_many :course_classes, -> { order(id: :asc) }, dependent: :destroy
  has_many :company_courses, dependent: :destroy
  has_many :companies, through: :company_courses

  validates :name, :description, presence: true

  delegate :can_be_viewed?, to: :viewable_company_course, prefix: false, allow_nil: true

  def viewable_company_course
    company_courses.find { |cc| cc.can_be_viewed? && Current.user.company.id == cc.company_id }
  end
end
