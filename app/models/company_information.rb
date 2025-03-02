class CompanyInformation < ApplicationRecord
  validates :name, presence: true
  validates :postal_code, presence: true
  validates :address, presence: true
  validates :phone_number, presence: true
  validates :invoice_registration_number, presence: true, 
            format: { with: /\AT\d{13}\z/, message: "は「T」で始まる13桁の数字が必要です" }
end 