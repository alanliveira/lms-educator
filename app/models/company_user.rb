class CompanyUser < ApplicationRecord
  belongs_to :company
  belongs_to :user

  validates :owner, uniqueness: { scope: :company_id }, if: -> { owner }
end
