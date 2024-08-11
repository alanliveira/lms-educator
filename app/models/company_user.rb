class CompanyUser < ApplicationRecord
  acts_as_paranoid

  belongs_to :company
  belongs_to :user

  validates :owner, uniqueness: { scope: :company_id }, if: -> { owner }

  before_destroy :soft_delete_user

  private

  def soft_delete_user
    user.update!(deleted_at: current_time_from_proper_timezone)
  end
end
