class CertificateIssuance < ApplicationRecord
  belongs_to :certificate
  belongs_to :course
  belongs_to :user

  before_validation :generate_verification_code, on: :create

  validates :verification_code, presence: true, uniqueness: true
  validates :completed_at, presence: true
  validates :user_id, uniqueness: { scope: :certificate_id }

  private

  def generate_verification_code
    self.verification_code ||= SecureRandom.hex(12).upcase
  end
end
