class Course < ApplicationRecord
  has_many :course_classes, dependent: :destroy

  has_one_attached :thumbnail

  validates :name, :description, presence: true
end
