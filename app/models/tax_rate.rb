class TaxRate < ApplicationRecord
  # この税率を参照している商品がある場合は削除禁止
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :start_date, presence: true
  validate :end_date_after_start_date, if: -> { end_date.present? }

  private

  def end_date_after_start_date
    if end_date <= start_date
      errors.add(:end_date, "は開始日より後の日付にしてください")
    end
  end
end
