class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :unit, optional: true

  validates :quantity, presence: true,
    numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 },
    unless: :marked_for_destruction?

  validates :product, presence: true, unless: :marked_for_destruction?

  def subtotal
    return 0 if unit_price.nil? || quantity.nil? || tax_rate.nil?
    (unit_price * quantity * (1 + tax_rate / 100.0)).round
  end

  def subtotal_without_tax
    return 0 if unit_price.nil? || quantity.nil?
    (unit_price * quantity).round
  end
end
