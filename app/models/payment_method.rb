class PaymentMethod < ApplicationRecord
  # この支払方法を参照している受注がある場合は削除禁止
  has_many :orders, dependent: :restrict_with_error
  has_many :customers, dependent: :nullify
end
