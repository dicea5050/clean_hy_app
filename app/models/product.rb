class Product < ApplicationRecord
  belongs_to :tax_rate
  belongs_to :product_category

  validates :product_code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :tax_rate_id, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # 利用可能な商品を取得するスコープを修正
  scope :available, -> {
    where(is_public: true)
    .where("stock > 0 OR stock IS NULL")
  }

  # とりあえず全商品を表示する場合
  # scope :available, -> { all }

  # 在庫があるかチェックするメソッド
  def in_stock?(quantity = 1)
    stock.nil? || stock >= quantity
  end

  # 単価が固定かどうかを判断するメソッド
  def fixed_price?
    price.present?
  end

  # 値引き対象商品かどうかを判断するメソッド
  def discount_target?
    is_discount_target
  end
end
