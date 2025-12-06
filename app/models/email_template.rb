class EmailTemplate < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :subject, presence: true
  validates :body, presence: true
  validate :only_one_active_template, if: :will_save_change_to_is_active?

  # テンプレート名の定義
  TEMPLATE_NAMES = {
    invoice_delivery: "invoice_delivery"
  }.freeze

  scope :active, -> { where(is_active: true) }

  # 他の有効なテンプレートを取得
  def other_active_template
    EmailTemplate.where(is_active: true).where.not(id: id).first
  end

  # 有効化可能かどうか
  def can_activate?
    !other_active_template.present?
  end

  # テンプレート変数を置換
  def render_subject(variables = {})
    replace_variables(subject, variables)
  end

  def render_body(variables = {})
    replace_variables(body, variables)
  end

  # デフォルトテンプレートを取得
  def self.default_invoice_delivery
    find_or_create_by(name: TEMPLATE_NAMES[:invoice_delivery]) do |template|
      template.subject = "【{{company_name}}】請求書 {{invoice_number}} をお送りいたします"
      template.body = <<~BODY
        {{customer_name}} 御中

        平素よりお世話になっております。
        {{company_name}}でございます。

        この度は、以下の請求書をお送りいたします。

        【請求書情報】
        請求書番号：{{invoice_number}}
        請求日：{{invoice_date}}
        {{#if due_date}}支払期限：{{due_date}}{{/if}}
        請求金額：{{total_amount}}

        請求書PDFを本メールに添付しておりますので、ご確認ください。

        ご不明な点がございましたら、お気軽にお問い合わせください。

        {{company_name}}
        {{#if company_phone}}TEL: {{company_phone}}{{/if}}
      BODY
      template.is_active = true
    end
  end

  private

  def only_one_active_template
    return unless is_active?

    other_active = other_active_template
    if other_active.present?
      errors.add(:is_active, "有効化するには、現在有効になっているテンプレート（#{other_active.name}）の有効化を先に解除してください")
    end
  end

  def replace_variables(text, variables)
    result = text.dup
    # まず条件分岐を処理
    variables.each do |key, value|
      # {{#if key}}...{{/if}} のパターンを処理
      pattern = /\{\{#if #{key}\}\}(.*?)\{\{\/if\}\}/m
      if value.present?
        result.gsub!(pattern, '\1')
      else
        result.gsub!(pattern, '')
      end
    end
    # 次に変数を置換
    variables.each do |key, value|
      result.gsub!("{{#{key}}}", value.to_s)
    end
    result
  end
end
