class Customer < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_secure_password validations: false # バリデーションは無効化して必須項目にしない

  # 請求書送付方法の列挙型を定義
  enum :invoice_delivery_method, { electronic: 0, postal: 1 }

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
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :invoice_delivery_method, presence: true
  # パスワードは任意項目

  def name
    company_name
  end

  # i18n用のヘルパーメソッド
  def invoice_delivery_method_i18n
    I18n.t("enums.customer.invoice_delivery_method.#{invoice_delivery_method}")
  end
end
