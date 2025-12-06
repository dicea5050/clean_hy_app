class ProductCategory < ApplicationRecord
  # products.product_category_id に NOT NULL 制約があるため nullify は使えない
  # 関連が存在する場合は削除を禁止してエラーにする
  has_many :products, dependent: :restrict_with_error
  has_many :budgets, dependent: :destroy
  has_many :product_aggregation_groups, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
