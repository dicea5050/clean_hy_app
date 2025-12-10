class DeliveryLocation < ApplicationRecord
  belongs_to :customer
  has_many :orders, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: { message: "納品先名は必須です" }
  validates :address, presence: { message: "住所は必須です" }

  # 表示用の納品先名（（本社）を（基本）に置き換え）
  def display_name
    name.to_s.gsub('（本社）', '（基本）')
  end
end
