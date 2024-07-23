class CourseClass < ApplicationRecord
  has_rich_text :description
  has_one_attached :thumbnail

  validates :name, :description, :thumbnail, presence: true
end
