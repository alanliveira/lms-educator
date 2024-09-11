class Course < ApplicationRecord
  acts_as_paranoid

  has_many :course_classes, dependent: :destroy

  has_one_attached :thumbnail

  validates :name, :description, presence: true
end
