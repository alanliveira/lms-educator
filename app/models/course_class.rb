class CourseClass < ApplicationRecord
  acts_as_paranoid

  belongs_to :course

  has_one_attached :thumbnail
  has_one_attached :video

  has_many_attached :attachments

  validates :name, :description, presence: true
end
