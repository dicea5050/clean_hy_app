class Budget < ApplicationRecord
  belongs_to :product_category
  belongs_to :product, optional: true

  validates :fiscal_year, presence: true, numericality: { only_integer: true, greater_than: 2000, less_than: 3000 }
  validates :product_category_id, presence: true
  validates :budget_amount, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :fiscal_year, uniqueness: { scope: [:product_category_id, :product_id, :aggregation_group_name], message: "この年度・事業部・商品・グループの組み合わせは既に登録されています" }

  scope :by_fiscal_year, ->(year) { where(fiscal_year: year) }
  scope :by_category, ->(category_id) { where(product_category_id: category_id) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :category_budgets, -> { where(product_id: nil) }
  scope :product_budgets, -> { where.not(product_id: nil) }
  scope :by_aggregation_group, ->(group_name) { where(aggregation_group_name: group_name) }
  scope :individual_budgets, -> { where(aggregation_group_name: nil) }
  scope :grouped_budgets, -> { where.not(aggregation_group_name: nil) }

  # 事業部ごとの予算を取得
  def self.category_budget_for(fiscal_year, product_category_id)
    find_by(fiscal_year: fiscal_year, product_category_id: product_category_id, product_id: nil)
  end

  # 商品ごとの予算を取得
  def self.product_budget_for(fiscal_year, product_category_id, product_id)
    find_by(fiscal_year: fiscal_year, product_category_id: product_category_id, product_id: product_id)
  end

  # 集計グループごとの予算を取得（事業部×年度×グループ名）
  def self.group_budgets_for(fiscal_year, product_category_id, group_name)
    where(fiscal_year: fiscal_year, product_category_id: product_category_id, aggregation_group_name: group_name)
  end

  # 個別表示かどうか（集計グループ名がnilの場合は個別表示）
  def individual?
    aggregation_group_name.nil?
  end

  # グループ表示かどうか
  def grouped?
    !individual?
  end
end

