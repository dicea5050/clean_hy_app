class Invoice < ApplicationRecord
  belongs_to :customer
  has_many :invoice_orders, dependent: :destroy
  has_many :orders, through: :invoice_orders
  has_many :payment_records, dependent: :destroy

  # payment_recordsのネストした属性を受け入れる
  accepts_nested_attributes_for :payment_records,
                               allow_destroy: true,
                               reject_if: proc { |attributes| attributes['payment_date'].blank? || attributes['amount'].blank? }

  # 承認状態の定義を先に行う
  APPROVAL_STATUSES = {
    pending: "未申請",
    waiting: "承認待ち",
    approved: "承認済み",
    rejected: "差し戻し"
  }.freeze

  validates :invoice_date, presence: true
  validates :customer_id, presence: true
  validates :invoice_number, presence: true, uniqueness: { conditions: -> { where.not(id: nil) } }
  validates :approval_status, presence: true, inclusion: { in: APPROVAL_STATUSES.values }

  before_validation :generate_invoice_number, on: :create
  before_validation :set_default_approval_status, on: :create

  # 請求書番号を生成（年月ごとにリセットされる連番）
  def generate_invoice_number
    return if invoice_number.present?

    date_part = invoice_date.strftime("%y%m")
    same_month_invoices = Invoice.where(
      "EXTRACT(YEAR FROM invoice_date) = ? AND EXTRACT(MONTH FROM invoice_date) = ?",
      invoice_date.year,
      invoice_date.month
    ).order(:created_at)

    # 現在存在する（削除されていない）請求書の数を取得
    position = same_month_invoices.count + 1

    # 新しい請求書番号を生成
    loop do
      id_part = sprintf("%04d", position)
      temp_number = "INV-#{date_part}-#{id_part}"

      # この番号が使用されていなければ採用
      unless Invoice.exists?(invoice_number: temp_number)
        self.invoice_number = temp_number
        break
      end

      position += 1
    end
  end

  # デフォルトの承認状態を設定
  def set_default_approval_status
    self.approval_status ||= APPROVAL_STATUSES[:pending]
  end

  # 合計金額（税抜）
  def total_amount_without_tax
    orders.sum do |order|
      order.order_items.sum(&:subtotal_without_tax)
    end
  end

  # 合計金額（税込）
  def total_amount
    orders.sum do |order|
      order.order_items.sum(&:subtotal)
    end
  end

  # 入金済み金額の合計
  def total_paid_amount
    payment_records.sum(:amount)
  end

  # 未入金金額
  def unpaid_amount
    total_amount - total_paid_amount
  end

  # 承認状態に応じたバッジのクラスを返すヘルパーメソッド
  def approval_status_badge_class
    case approval_status
    when "未申請"
      "badge bg-secondary"
    when "承認待ち"
      "badge bg-warning"
    when "承認済み"
      "badge bg-success"
    when "差し戻し"
      "badge bg-danger"
    end
  end
end
