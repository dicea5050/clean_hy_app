class InvoiceApproval < ApplicationRecord
  belongs_to :invoice
  belongs_to :approver, polymorphic: true, optional: true

  # 承認状態の定義
  STATUSES = {
    pending: "承認待ち",
    approved: "承認済み",
    rejected: "差し戻し"
  }.freeze

  validates :invoice_id, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES.values }
  # approverは承認時点で設定されるため、作成時はoptional
  validates :approver, presence: true, if: -> { status == STATUSES[:approved] || status == STATUSES[:rejected] }

  # 承認時に自動的に承認日時を設定
  before_save :set_approved_at, if: :status_changed_to_approved?

  private

  def status_changed_to_approved?
    status_changed? && status == STATUSES[:approved]
  end

  def set_approved_at
    self.approved_at = Time.current
  end
end
