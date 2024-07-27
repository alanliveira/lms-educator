class CourseClass < ApplicationRecord
  belongs_to :course

  has_one_attached :thumbnail
  has_one_attached :video
  has_many_attached :attachments

  validates :name, :description, :video, presence: true
end
