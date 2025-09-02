class ProductCategory < ApplicationRecord
  has_many :products, dependent: :nullify

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
