class Order < ApplicationRecord
  belongs_to :customer
  belongs_to :payment_method, optional: true
  belongs_to :delivery_location, optional: true
  has_many :order_items, dependent: :destroy
  has_many :invoice_orders, dependent: :destroy
  has_many :invoices, through: :invoice_orders

  accepts_nested_attributes_for :order_items,
    allow_destroy: true,
    reject_if: :all_blank

  validates :order_date, presence: true
  validates :customer_id, presence: true
  validates :delivery_location_id, presence: true

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

  def self.search(params)
    return all if params.blank?

    rel = all

    # 顧客コードでの検索
    if params[:customer_code].present?
      rel = rel.joins(:customer)
               .where("customers.customer_code LIKE ?", "%#{params[:customer_code]}%")
    end

    # 取引先名での検索
    if params[:customer_name].present?
      rel = rel.joins(:customer)
               .where("customers.company_name LIKE ?", "%#{params[:customer_name]}%")
    end

    # 受注番号での検索
    if params[:order_number].present?
      rel = rel.where("id IN (
                SELECT id FROM orders
                WHERE CONCAT('ORD-',
                             TO_CHAR(order_date, 'YYMM'),
                             '-',
                             LPAD(ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM order_date),
                                                     EXTRACT(MONTH FROM order_date)
                                           ORDER BY created_at), 4, '0')
                            ) LIKE ?)",
                "%#{params[:order_number]}%")
    end

    # 受注日での検索
    if params[:order_date_from].present?
      rel = rel.where("order_date >= ?", params[:order_date_from])
    end
    if params[:order_date_to].present?
      rel = rel.where("order_date <= ?", params[:order_date_to])
    end

    # 予定納品日での検索
    if params[:expected_delivery_date_from].present?
      rel = rel.where("expected_delivery_date >= ?", params[:expected_delivery_date_from])
    end
    if params[:expected_delivery_date_to].present?
      rel = rel.where("expected_delivery_date <= ?", params[:expected_delivery_date_to])
    end

    # 確定納品日での検索
    if params[:actual_delivery_date_from].present?
      rel = rel.where("actual_delivery_date >= ?", params[:actual_delivery_date_from])
    end
    if params[:actual_delivery_date_to].present?
      rel = rel.where("actual_delivery_date <= ?", params[:actual_delivery_date_to])
    end

    # 合計金額（税抜）での範囲検索
    if params[:total_without_tax_from].present? || params[:total_without_tax_to].present?
      # サブクエリで合計金額を計算し、その結果でフィルタリング
      subquery = OrderItem.select("order_id, SUM(unit_price * quantity) as total")
                        .group(:order_id)

      order_ids = subquery

      if params[:total_without_tax_from].present?
        order_ids = order_ids.having("SUM(unit_price * quantity) >= ?", params[:total_without_tax_from].to_i)
      end

      if params[:total_without_tax_to].present?
        order_ids = order_ids.having("SUM(unit_price * quantity) <= ?", params[:total_without_tax_to].to_i)
      end

      rel = rel.where(id: order_ids.pluck(:order_id))
    end

    # 支払い方法での検索（複数選択可）
    if params[:payment_method_ids].present? && params[:payment_method_ids].any?(&:present?)
      rel = rel.where(payment_method_id: params[:payment_method_ids])
    end

    # 請求状況での検索
    if params[:invoice_status].present?
      case params[:invoice_status]
      when "invoiced"
        rel = rel.where(id: InvoiceOrder.select(:order_id))
      when "not_invoiced"
        rel = rel.where.not(id: InvoiceOrder.select(:order_id))
      end
    end

    # 請求締日での検索
    if params[:billing_closing_day].present?
      rel = rel.joins(:customer)
               .where("customers.billing_closing_day = ?", params[:billing_closing_day])
    end

    rel
  end
end
