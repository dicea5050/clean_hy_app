class Invoice < ApplicationRecord
  belongs_to :customer
  has_many :invoice_orders, dependent: :destroy
  has_many :orders, through: :invoice_orders
  
  # 承認状態の定義を先に行う
  APPROVAL_STATUSES = {
    pending: '未申請',
    waiting: '承認待ち',
    approved: '承認済み',
    rejected: '差し戻し'
  }.freeze
  
  validates :invoice_date, presence: true
  validates :customer_id, presence: true
  validates :invoice_number, presence: true, uniqueness: true
  validates :approval_status, presence: true, inclusion: { in: APPROVAL_STATUSES.values }
  
  before_validation :generate_invoice_number, on: :create
  
  # 請求書番号を生成（年月ごとにリセットされる連番）
  def generate_invoice_number
    return if invoice_number.present?
    
    date_part = invoice_date.strftime("%y%m")
    same_month_invoices = Invoice.where(
      "EXTRACT(YEAR FROM invoice_date) = ? AND EXTRACT(MONTH FROM invoice_date) = ?",
      invoice_date.year,
      invoice_date.month
    ).order(:created_at)
    
    position = same_month_invoices.count + 1
    id_part = sprintf("%04d", position)
    
    self.invoice_number = "INV-#{date_part}-#{id_part}"
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

  # 承認状態に応じたバッジのクラスを返すヘルパーメソッド
  def approval_status_badge_class
    case approval_status
    when '未申請'
      'badge bg-secondary'
    when '承認待ち'
      'badge bg-warning'
    when '承認済み'
      'badge bg-success'
    when '差し戻し'
      'badge bg-danger'
    end
  end
end 