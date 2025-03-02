class Customer < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_secure_password validations: false # バリデーションは無効化して必須項目にしない
  
  def password_set?
    password_digest.present?
  end
  
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
  # パスワードは任意項目

  def name
    contact_name # または company_name、あるいは "#{company_name} (#{contact_name})" など
  end
end 