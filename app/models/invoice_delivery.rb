class InvoiceDelivery < ApplicationRecord
  belongs_to :invoice
  belongs_to :sender, class_name: "Administrator", foreign_key: "sent_by", optional: true

  # 送付方法の定義
  DELIVERY_METHODS = {
    email: "email",
    postal: "postal"
  }.freeze

  # 送付ステータスの定義
  DELIVERY_STATUSES = {
    pending: "pending",
    sent: "sent",
    printed: "printed",
    downloaded: "downloaded",
    failed: "failed"
  }.freeze

  validates :invoice_id, presence: true
  validates :delivery_method, presence: true, inclusion: { in: DELIVERY_METHODS.values }
  validates :delivery_status, presence: true, inclusion: { in: DELIVERY_STATUSES.values }
  validate :active_template_required_for_email, if: -> { delivery_method == DELIVERY_METHODS[:email] }

  # メール送信時に有効なテンプレートが必要
  def active_template_required_for_email
    unless EmailTemplate.active.exists?
      errors.add(:base, "メールテンプレートを有効化してください")
    end
  end

  # スコープ
  scope :email_deliveries, -> { where(delivery_method: DELIVERY_METHODS[:email]) }
  scope :postal_deliveries, -> { where(delivery_method: DELIVERY_METHODS[:postal]) }
  scope :pending, -> { where(delivery_status: DELIVERY_STATUSES[:pending]) }
  scope :sent, -> { where(delivery_status: DELIVERY_STATUSES[:sent]) }
  scope :failed, -> { where(delivery_status: DELIVERY_STATUSES[:failed]) }
  scope :recent, -> { order(sent_at: :desc) }

  # SESイベントタイプの定義
  SES_EVENT_TYPES = {
    send: "Send",
    delivery: "Delivery",
    bounce: "Bounce",
    complaint: "Complaint",
    reject: "Reject"
  }.freeze

  # SESイベントを処理して状態を更新
  def process_ses_event(event_type, event_timestamp, error_message = nil)
    self.ses_event_type = event_type
    self.ses_event_timestamp = event_timestamp
    self.ses_error_message = error_message if error_message.present?

    case event_type
    when SES_EVENT_TYPES[:delivery]
      # 送信成功
      self.delivery_status = DELIVERY_STATUSES[:sent]
      self.sent_at = event_timestamp
      save!
      # 請求書の状態を「送付済み」に更新
      invoice.update!(approval_status: Invoice::APPROVAL_STATUSES[:sent])
    when SES_EVENT_TYPES[:bounce], SES_EVENT_TYPES[:reject]
      # 送信失敗
      self.delivery_status = DELIVERY_STATUSES[:failed]
      save!
      # 請求書の状態を「エラー」に更新
      invoice.update!(approval_status: Invoice::APPROVAL_STATUSES[:error])
    when SES_EVENT_TYPES[:complaint]
      # 苦情（送信は成功しているが、受信者が苦情を申し立てた）
      # 送信自体は成功しているので、状態は変更しない
      save!
    end
  end

  # 送付済みかどうか
  def sent?
    delivery_status == DELIVERY_STATUSES[:sent]
  end

  # メール送信済みかどうか
  def email_sent?
    delivery_method == DELIVERY_METHODS[:email] && sent?
  end

  # 再送信かどうか
  def resend?
    is_resend == true
  end
end
