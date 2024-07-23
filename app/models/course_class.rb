class CourseClass < ApplicationRecord
  belongs_to :course

  has_rich_text  :description
  has_one_attached :thumbnail
end
