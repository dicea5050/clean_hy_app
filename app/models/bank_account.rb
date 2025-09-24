class BankAccount < ApplicationRecord
  validates :bank_name, presence: true
  validates :branch_name, presence: true
  validates :account_type, presence: true, inclusion: { in: [ "普通", "当座" ] }
  validates :account_number, presence: true
  validates :account_holder, presence: true

  # 請求書PDFで銀行口座一覧を参照するため、請求書が存在する間は削除禁止
  before_destroy :prevent_destroy_if_invoices_exist

  private

  def prevent_destroy_if_invoices_exist
    if defined?(Invoice) && Invoice.exists?
      errors.add(:base, "請求書が存在するため銀行口座を削除できません。請求書がない状態で削除してください。")
      throw(:abort)
    end
  end
end
