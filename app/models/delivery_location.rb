class DeliveryLocation < ApplicationRecord
  belongs_to :customer

  # バリデーション
  validates :name, presence: { message: '納品先名は必須です' }
  validates :address, presence: { message: '住所は必須です' }
end
