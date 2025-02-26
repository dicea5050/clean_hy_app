class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 }
  
  def subtotal
    return 0 if unit_price.nil? || quantity.nil? || tax_rate.nil?
    (unit_price * quantity * (1 + tax_rate / 100.0)).round
  end
end 