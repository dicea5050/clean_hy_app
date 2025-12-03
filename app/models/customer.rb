class Customer < ApplicationRecord
  belongs_to :payment_method, optional: true
  has_many :orders, dependent: :destroy
  has_many :delivery_locations, dependent: :destroy
  has_secure_password validations: false # バリデーションは無効化して必須項目にしない

  # 請求書送付方法の列挙型を定義
  enum :invoice_delivery_method, { electronic: 0, postal: 1 }

  # 請求締日の選択肢を定義
  BILLING_CLOSING_DAYS = [
    [ "5日", "5" ],
    [ "10日", "10" ],
    [ "15日", "15" ],
    [ "20日", "20" ],
    [ "25日", "25" ],
    [ "月末", "month_end" ]
  ].freeze

  # 請求書送付方法の選択肢を定義
  INVOICE_DELIVERY_METHOD_OPTIONS = {
    "\u96FB\u5B50\u8ACB\u6C42" => "electronic",
    "\u90F5\u9001" => "postal"
  }.freeze

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
  validates :payment_method_id, presence: true
  validates :invoice_delivery_method, presence: true
  validates :billing_closing_day, presence: true, inclusion: { in: BILLING_CLOSING_DAYS.map(&:last) }
  # パスワードは任意項目

  # 電子請求の場合のみメールアドレスを必須にする
  validate :email_required_for_electronic_invoice

  def email_required_for_electronic_invoice
    if invoice_delivery_method == "electronic" && email.blank?
      errors.add(:email, "\u96FB\u5B50\u8ACB\u6C42\u3092\u9078\u629E\u3057\u305F\u5834\u5408\u306F\u30E1\u30FC\u30EB\u30A2\u30C9\u30EC\u30B9\u304C\u5FC5\u9808\u3067\u3059")
    end
  end

  def name
    company_name
  end

  # i18n用のヘルパーメソッド
  def invoice_delivery_method_i18n
    I18n.t("enums.customer.invoice_delivery_method.#{invoice_delivery_method}")
  end

  # 請求書送付方法の表示テキストを返す
  def invoice_delivery_method_display
    electronic? ? "電子請求" : "郵送"
  end

  # 請求書送付方法に応じたバッジのクラスを返す
  def invoice_delivery_method_badge_class
    electronic? ? "badge bg-info" : "badge bg-invoiced"
  end

  # 請求締日の表示用メソッド
  def billing_closing_day_display
    return "" if billing_closing_day.blank?

    case billing_closing_day
    when "month_end"
      "月末"
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
