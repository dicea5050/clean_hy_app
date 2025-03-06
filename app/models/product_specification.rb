class ProductSpecification < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :is_active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(is_active: true) }
end
