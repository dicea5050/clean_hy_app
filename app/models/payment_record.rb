class PaymentRecord < ApplicationRecord
  belongs_to :invoice

  # 支払いタイプの定義
  PAYMENT_TYPES = {
    payment: "入金",
    offset: "相殺",
    fee: "支払手数料"
  }.freeze

  validates :payment_date, presence: true
  validates :payment_type, presence: true, inclusion: { in: PAYMENT_TYPES.values }
  validates :amount, presence: true, numericality: { greater_than: 0 }
end
