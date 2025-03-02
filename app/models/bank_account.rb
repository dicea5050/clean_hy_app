class BankAccount < ApplicationRecord
  validates :bank_name, presence: true
  validates :branch_name, presence: true
  validates :account_type, presence: true, inclusion: { in: ['普通', '当座'] }
  validates :account_number, presence: true
  validates :account_holder, presence: true
end 