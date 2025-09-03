class Customer < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_many :delivery_locations, dependent: :destroy
  has_secure_password validations: false # バリデーションは無効化して必須項目にしない

  # 請求書送付方法の列挙型を定義
  enum :invoice_delivery_method, { electronic: 0, postal: 1 }

  # 請求締日の選択肢を定義
  BILLING_CLOSING_DAYS = [
    ['5日', '5'],
    ['10日', '10'],
    ['15日', '15'],
    ['20日', '20'],
    ['25日', '25'],
    ['月末', 'month_end']
  ].freeze

  # コールバック：顧客作成時と更新時に本社納品先も同期する
  after_create :create_main_office_delivery_location
  after_update :update_main_office_delivery_location, if: :address_changed?

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
  validates :billing_closing_day, inclusion: { in: BILLING_CLOSING_DAYS.map(&:last) }, allow_blank: true
  # パスワードは任意項目

  def name
    company_name
  end

  # i18n用のヘルパーメソッド
  def invoice_delivery_method_i18n
    I18n.t("enums.customer.invoice_delivery_method.#{invoice_delivery_method}")
  end

  # 請求締日の表示用メソッド
  def billing_closing_day_display
    return '' if billing_closing_day.blank?
    
    case billing_closing_day
    when 'month_end'
      '月末'
    else
      "#{billing_closing_day}日"
    end
  end

  private

  # 顧客作成時に本社納品先を自動登録
  def create_main_office_delivery_location
    delivery_locations.create(
      name: "#{company_name}（本社）",
      postal_code: postal_code,
      address: address,
      phone: phone_number,
      contact_person: contact_name,
      is_main_office: true
    )
  end

  # 顧客情報更新時に本社納品先も更新
  def update_main_office_delivery_location
    main_office = delivery_locations.find_by(is_main_office: true)

    if main_office
      main_office.update(
        name: "#{company_name}（本社）",
        postal_code: postal_code,
        address: address,
        phone: phone_number,
        contact_person: contact_name
      )
    else
      # 本社情報がなければ新規作成
      create_main_office_delivery_location
    end
  end

  # 住所関連のフィールドが変更されたかを確認
  def address_changed?
    saved_change_to_postal_code? ||
    saved_change_to_address? ||
    saved_change_to_company_name? ||
    saved_change_to_phone_number? ||
    saved_change_to_contact_name?
  end
end
