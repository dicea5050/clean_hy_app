class Customer < ApplicationRecord
  has_many :orders, dependent: :destroy
  
  def display_name
    company_name
  end

  validates :customer_code, presence: true, uniqueness: true
  validates :company_name, presence: true
  validates :postal_code, presence: true
  validates :address, presence: true
  validates :contact_name, presence: true
  validates :phone_number, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end 