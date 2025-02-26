class Product < ApplicationRecord
  belongs_to :tax_rate
  
  validates :product_code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :tax_rate_id, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end 