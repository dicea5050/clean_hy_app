class ProductAggregationGroup < ApplicationRecord
  belongs_to :product_category
  belongs_to :product

  validates :fiscal_year, presence: true, numericality: { only_integer: true, greater_than: 2000, less_than: 3000 }
  validates :product_category_id, presence: true
  validates :product_id, presence: true
  validates :group_name, presence: true
  validates :fiscal_year, uniqueness: { scope: [:product_category_id, :product_id], message: "この年度・事業部・商品の組み合わせは既に登録されています" }

  scope :by_fiscal_year, ->(year) { where(fiscal_year: year) }
  scope :by_category, ->(category_id) { where(product_category_id: category_id) }
  scope :by_group_code, ->(code) { where(group_code: code) }
  scope :by_group_name, ->(name) { where(group_name: name) }

  # 事業部×年度×グループ名でグループ化された商品を取得
  def self.grouped_by_name(fiscal_year, product_category_id)
    where(fiscal_year: fiscal_year, product_category_id: product_category_id)
      .group(:group_name)
      .pluck(:group_name)
      .map do |group_name|
        {
          group_name: group_name,
          products: where(fiscal_year: fiscal_year, product_category_id: product_category_id, group_name: group_name).includes(:product)
        }
      end
  end
end
