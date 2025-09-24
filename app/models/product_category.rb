class ProductCategory < ApplicationRecord
  # products.product_category_id に NOT NULL 制約があるため nullify は使えない
  # 関連が存在する場合は削除を禁止してエラーにする
  has_many :products, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
