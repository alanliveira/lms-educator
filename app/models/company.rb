class Company < ApplicationRecord
  acts_as_paranoid

  has_one_attached :logo

  has_many :company_users, dependent: :destroy
  has_many :users, through: :company_users
  has_many :company_courses, dependent: :destroy
  has_many :courses, through: :company_courses

  validates :name, :fantasy_name, :address, :cnpj, :users, :logo, presence: true

  accepts_nested_attributes_for :users
  accepts_nested_attributes_for :company_courses

  def owner
    owner = company_users.where(owner: true).first
    owner&.user
  end
end
