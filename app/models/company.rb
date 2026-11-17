class Company < ApplicationRecord
  acts_as_paranoid

  # Subdomain of the company created by the initial setup (see SetupController).
  # It is also the fallback company used whenever a record has no company yet.
  DEFAULT_SUBDOMAIN = "admin".freeze

  has_one_attached :logo

  # The company created by the initial setup, used as the system default.
  def self.default
    find_by(subdomain: DEFAULT_SUBDOMAIN)
  end

  validates :logo,
            content_type: %w[image/png image/jpeg image/webp],
            size: { less_than_or_equal_to: 2.megabytes }

  has_many :company_users, dependent: :destroy
  has_many :users, through: :company_users
  has_one :owner_company_user, -> { where(owner: true) }, class_name: "CompanyUser"
  has_one :owner, through: :owner_company_user, source: :user
  has_many :company_courses, dependent: :destroy
  has_many :courses, through: :company_courses

  validates :name, :fantasy_name, :address, :cnpj, :users, :logo, :subdomain, presence: true
  validates :subdomain,
            uniqueness: true,
            exclusion: { in: %w[www] },
            format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  normalizes :subdomain, with: -> { _1.strip.downcase }

  accepts_nested_attributes_for :users
  accepts_nested_attributes_for :company_courses
end
