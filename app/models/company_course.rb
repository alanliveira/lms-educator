class CompanyCourse < ApplicationRecord
  belongs_to :company
  belongs_to :course

  validates :course_id, uniqueness: { scope: :company_id }
end
