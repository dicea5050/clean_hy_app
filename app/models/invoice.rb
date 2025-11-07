class Invoice < ApplicationRecord
  belongs_to :customer
  has_many :invoice_orders, dependent: :destroy
  has_many :orders, through: :invoice_orders
  has_many :invoice_approvals, dependent: :destroy
  # 充当記録のみを取得（invoice_idが存在するpayment_records）
  has_many :payment_records, -> { where.not(invoice_id: nil) }, class_name: 'PaymentRecord', foreign_key: 'invoice_id', dependent: :destroy

  # 承認状態の定義を先に行う
  APPROVAL_STATUSES = {
    waiting: "承認待ち",
    approved: "承認済み",
    rejected: "差し戻し"
  }.freeze

  # 入金状況の定義
  PAYMENT_STATUSES = {
    unpaid: "未入金",
    paid: "入金済",
    partial: "一部未入金"
  }.freeze

  validates :invoice_date, presence: true
  validates :customer_id, presence: true
  validates :invoice_number, presence: true, uniqueness: { conditions: -> { where.not(id: nil) } }
  validates :approval_status, presence: true, inclusion: { in: APPROVAL_STATUSES.values }

  before_validation :generate_invoice_number, on: :create
  before_validation :set_default_approval_status, on: :create
  after_create :create_initial_invoice_approval

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
    self.approval_status ||= APPROVAL_STATUSES[:waiting]
  end

  # 請求書作成時にInvoiceApprovalレコードを自動作成
  def create_initial_invoice_approval
    # 既にInvoiceApprovalが存在する場合は作成しない
    return if invoice_approvals.exists?

    invoice_approvals.create!(
      status: InvoiceApproval::STATUSES[:pending]
      # approverは承認時点で設定されるため、作成時は設定しない
    )
  end

  # 合計金額（税抜）
  def total_amount_without_tax
    orders.sum do |order|
      order.order_items.sum(&:subtotal_without_tax)
    end
  end

  # 合計金額（税込）
  def total_amount
    result = orders.sum do |order|
      order.order_items.sum(&:subtotal) || 0
    end
    result || 0
  end

  # 入金済み金額の合計（充当記録のpaid_amountを集計）
  def total_paid_amount
    PaymentRecord.where(invoice_id: id).sum(:paid_amount) || 0
  end

  # 未入金金額
  def unpaid_amount
    calculated_total = total_amount
    calculated_paid = total_paid_amount
    result = calculated_total - calculated_paid
    
    # デバッグログ（必要に応じて）
    Rails.logger.debug "Invoice #{id} unpaid_amount計算: total=#{calculated_total}, paid=#{calculated_paid}, unpaid=#{result}" if Rails.env.development?
    
    result
  end

  # 未入金金額（remaining_amountの別名）
  def remaining_amount
    unpaid_amount
  end

  # 承認状態に応じたバッジのクラスを返すヘルパーメソッド
  def approval_status_badge_class
    case approval_status
    when "承認待ち"
      "badge bg-warning"
    when "承認済み"
      "badge bg-success"
    when "差し戻し"
      "badge bg-danger"
    else
      "badge bg-secondary"
    end
  end

  # 入金状況ステータス
  def payment_status
    if total_paid_amount == 0
      PAYMENT_STATUSES[:unpaid]
    elsif unpaid_amount == 0
      PAYMENT_STATUSES[:paid]
    else
      PAYMENT_STATUSES[:partial]
    end
  end

  # 入金状況に応じたバッジのクラスを返すヘルパーメソッド
  def payment_status_badge_class
    case payment_status
    when "未入金"
      "badge bg-danger"
    when "入金済"
      "badge bg-success"
    when "一部未入金"
      "badge bg-warning"
    end
  end

  # 顧客コードによる検索スコープ
  scope :by_customer_code, ->(customer_code) {
    joins(:customer).where("customers.customer_code LIKE ?", "%#{customer_code}%") if customer_code.present?
  }

  # 同一顧客の繰越金額（未入金請求書の合計）を計算
  # 承認済みの請求書で未入金額があるものの合計を返す
  # exclude_invoice_id: 繰越金額の計算から除外する請求書ID（edit/show画面で現在の請求書を除外するため）
  def self.carryover_amount_for_customer(customer_id, exclude_invoice_id: nil)
    return 0 if customer_id.blank?

    # 承認済みの請求書を取得
    approved_invoices = where(customer_id: customer_id, approval_status: APPROVAL_STATUSES[:approved])
                       .includes(orders: :order_items)

    # 特定の請求書を除外
    approved_invoices = approved_invoices.where.not(id: exclude_invoice_id) if exclude_invoice_id.present?

    # 未入金額がある請求書の未入金額を合計
    approved_invoices.sum { |invoice| [invoice.unpaid_amount, 0].max }
  end
end
