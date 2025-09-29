class Unit < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  # 削除可能かどうかをチェックするメソッド
  def can_be_destroyed?
    order_items.empty?
  end
end
