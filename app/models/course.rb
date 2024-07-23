class Course < ApplicationRecord
  has_many :course_classes

  has_rich_text  :description
  has_one_attached :thumbnail
end
