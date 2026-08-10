class CourseClass < ApplicationRecord
  acts_as_paranoid

  belongs_to :course

  has_one_attached :thumbnail
  has_one_attached :video

  has_many_attached :attachments
  has_many :course_class_completions, dependent: :destroy

  validates :thumbnail,
            content_type: %w[image/png image/jpeg image/webp],
            size: { less_than_or_equal_to: 2.megabytes }
  validates :video,
            content_type: "video/mp4",
            size: { less_than_or_equal_to: 500.megabytes }
  validates :attachments,
            content_type: ["application/pdf",
                           "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                           "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                           "application/vnd.openxmlformats-officedocument.presentationml.presentation"],
            size: { less_than_or_equal_to: 20.megabytes }

  validates :name, :description, presence: true
end
