class Course < ApplicationRecord
  acts_as_paranoid

  has_many :course_classes, dependent: :destroy

  has_one_attached :thumbnail

  has_many :course_classes, -> { order(id: :asc) }, dependent: :destroy
  has_one :certificate, dependent: :destroy
  has_many :certificate_issuances, dependent: :destroy
  has_many :company_courses, dependent: :destroy
  has_many :companies, through: :company_courses

  validates :name, :description, presence: true
  validates :workload_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  delegate :can_be_viewed?, to: :viewable_company_course, prefix: false, allow_nil: true

  def viewable_company_course
    company_courses.find { |cc| cc.can_be_viewed? && Current.company.id == cc.company_id }
  end
end
