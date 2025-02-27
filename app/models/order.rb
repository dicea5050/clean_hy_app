class Order < ApplicationRecord
  belongs_to :customer
  has_many :order_items, dependent: :destroy
  has_many :invoice_orders, dependent: :destroy
  has_many :invoices, through: :invoice_orders
  
  accepts_nested_attributes_for :order_items, allow_destroy: true

  validates :order_date, presence: true
  validates :customer_id, presence: true
  
  # 支払い方法の選択肢
  PAYMENT_METHODS = {
    "代引き（現金）" => "cash_on_delivery",
    "銀行振込" => "bank_transfer",
    "口座引き落し" => "bank_debit"
  }
  
  # 受注番号を生成するメソッド（年月ごとにリセットされる連番）
  def order_number
    # 受注日から年月を取得（YYMM形式）
    date_part = order_date.strftime("%y%m")
    
    # 同じ年月の受注を古い順に取得し、この受注が何番目かを特定
    same_month_orders = Order.where(
      "EXTRACT(YEAR FROM order_date) = ? AND EXTRACT(MONTH FROM order_date) = ?", 
      order_date.year, 
      order_date.month
    ).order(:created_at)
    
    # この受注の位置（1始まりの連番）を取得
    order_position = same_month_orders.pluck(:id).index(id) + 1
    
    # 連番を4桁にフォーマット
    id_part = sprintf("%04d", order_position)
    
    "ORD-#{date_part}-#{id_part}"
  end
  
  # 請求書に関連付けられているかどうかを判断するメソッド
  def invoiced?
    invoice_orders.exists?
  end
  
  # 紐づけられている請求書を取得するメソッド
  def related_invoices
    invoices.pluck(:invoice_number).join(", ")
  end
end 