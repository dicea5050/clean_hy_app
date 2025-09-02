class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true
  belongs_to :unit, optional: true

  validates :quantity, presence: true,
    numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 },
    unless: :marked_for_destruction?

  validates :product_id, presence: true, unless: :marked_for_destruction?

  # 表示用の商品名を取得（手動変更があればそれを、なければ商品マスタから）
  def display_product_name
    product_name_override.present? ? product_name_override : product&.name
  end

  def subtotal
    return 0 if unit_price.nil? || quantity.nil? || tax_rate.nil?
    # 値引き対象商品の場合はマイナスにする
    base_amount = unit_price * quantity
    base_amount = -base_amount if product&.is_discount_target?
    (base_amount * (1 + tax_rate / 100.0)).round
  end

  def subtotal_without_tax
    return 0 if unit_price.nil? || quantity.nil?
    # 値引き対象商品の場合はマイナスにする
    base_amount = unit_price * quantity
    base_amount = -base_amount if product&.is_discount_target?
    base_amount.round
  end
end
