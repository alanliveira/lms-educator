class User < ApplicationRecord
  acts_as_paranoid
  rolify

  has_secure_password

  generates_token_for :email_verification, expires_in: 1.day do
    email
  end

  generates_token_for :password_reset, expires_in: 20.minutes do
    password_salt.last(10)
  end

  has_one :company_user, dependent: :destroy
  has_one :company, through: :company_user

  has_many :histories, dependent: :destroy
  has_many :sessions, dependent: :destroy

  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password,
            allow_nil: true,
            length: { minimum: 8, maximum: 20 },
            format: { with: /(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#{::Regexp.last_match(0)}*]|.*[A-Z])/,
                      message: "Deve conter letras, números e pelo menos um caractere especial ou uma letra maiúscula" }

  normalizes :email, with: -> { _1.strip.downcase }

  accepts_nested_attributes_for :company_user
  accepts_nested_attributes_for :company

  before_validation if: :email_changed?, on: :update do
    self.verified = false
  end

  before_create do
    self.active = false unless active?
  end

  before_destroy do
    if company_user.owner?
      errors.add(:base, "Não é possível excluir um usuário que é proprietário de uma empresa")
      throw :abort
    end
  end

  after_create do
    add_role(:student) if roles.blank?
  end

  after_commit do
    UserMailer.with(user: self).email_verification.deliver_later if active? && !verified?
  end

  after_update if: :password_digest_previously_changed? do
    sessions.where.not(id: Current.session).delete_all
  end

  delegate :owner?, to: :company_user
end
