class PaymentRecord < ApplicationRecord
  belongs_to :invoice, optional: true
  belongs_to :customer

  VALID_CATEGORIES = [ "\u5165\u91D1\uFF08\u632F\u8FBC\uFF09", "\u5165\u91D1\uFF08\u73FE\u91D1\uFF09", "\u632F\u8FBC\u624B\u6570\u6599", "\u76F8\u6BBA", "\u8FD4\u91D1" ]

  validates :payment_date, presence: true
  validates :category, presence: true, inclusion: { in: VALID_CATEGORIES }
  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :paid_amount, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :customer, presence: true
  validates :invoice, presence: true, if: :invoice_required?

  # 数値変換のためのコールバック
  before_validation :convert_amounts_to_integer

  validate :paid_amount_not_exceed_amount

  # 未充当残高を計算
  def remaining_amount
    amount - paid_amount
  end

  # この入金記録が充当済みかどうか
  def fully_allocated?
    paid_amount >= amount
  end

  private

  def convert_amounts_to_integer
    self.amount = amount.to_i if amount.present?
    self.paid_amount = paid_amount.to_i if paid_amount.present?
  end

  def invoice_required?
    # 充当記録（invoice_idが設定されている）の場合は必須
    invoice_id.present?
  end

  def paid_amount_not_exceed_amount
    return unless amount.present? && paid_amount.present?

    if paid_amount > amount
      errors.add(:paid_amount, "は入金額を超えることはできません")
    end
  end
end
