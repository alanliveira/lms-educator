class User < ApplicationRecord
  rolify

  has_secure_password

  generates_token_for :email_verification, expires_in: 1.days do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end

  has_many :company, through: :company_users

  has_many :sessions, dependent: :destroy

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password,
            allow_nil: true,
            length: { minimum: 8, maximum: 20 },
            format: { with: /(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$&*]|.*[A-Z])/,
                      message: "Deve conter letras, números e pelo menos um caractere especial ou uma letra maiúscula" }

  normalizes :email, with: -> { _1.strip.downcase }

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_create do
    self.active = false
  end

  after_create do
    self.add_role(:student) if self.roles.blank?
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end
end
