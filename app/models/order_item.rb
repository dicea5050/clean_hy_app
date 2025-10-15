class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true
  belongs_to :product_specification, optional: true
  belongs_to :unit, optional: true

  # バリデーションを追加
  validates :quantity, numericality: { greater_than: 0, less_than_or_equal_to: 999999.999 }, allow_nil: true
  validates :unit_price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # バリデーションはOrderモデルで一元管理
  # validates :quantity, presence: { message: "数量を入力してください" },
  #   numericality: {
  #     only_integer: true,
  #     greater_than: 0,
  #     less_than_or_equal_to: 10,
  #     message: "数量は1〜10の整数で入力してください"
  #   },
  #   unless: :marked_for_destruction?

  # validates :product_id, presence: { message: "商品を選択してください" }, unless: :marked_for_destruction?
  # validates :product_specification_id, presence: { message: "規格を選択してください" }, unless: :marked_for_destruction?

  # 表示用の商品名を取得（手動変更があればそれを、なければ商品マスタから）
  def display_product_name
    product_name_override.present? ? product_name_override : product&.name
  end

  def display_product_specification_name
    product_specification&.name
  end

  def subtotal
    return 0 if unit_price.nil? || quantity.nil? || tax_rate.nil?
    # 値引き対象商品の場合はマイナスにする
    base_amount = unit_price * quantity
    base_amount = -base_amount if product&.is_discount_target?
    (base_amount * (1 + tax_rate / 100.0)).floor
  end

  def subtotal_without_tax
    return 0 if unit_price.nil? || quantity.nil?
    # 値引き対象商品の場合はマイナスにする
    base_amount = unit_price * quantity
    base_amount = -base_amount if product&.is_discount_target?
    base_amount.floor
  end
end
