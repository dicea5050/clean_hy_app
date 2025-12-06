class InvoiceDeliveryMailer < ApplicationMailer
  default from: -> { company_email }

  # 請求書メール送信
  def send_invoice(invoice, administrator, is_resend: false)
    @invoice = invoice
    @customer = invoice.customer
    @company_info = CompanyInformation.first
    @administrator = administrator
    @is_resend = is_resend
    @delivery_id = params[:delivery_id]

    # PDFを生成
    pdf = InvoicePdf.new(@invoice, @company_info, reissue: false)
    pdf_data = pdf.render

    # PDFを添付
    attachments["請求書_#{@invoice.invoice_number}.pdf"] = {
      mime_type: "application/pdf",
      content: pdf_data
    }

    # 有効なテンプレートを取得（なければエラー）
    template = EmailTemplate.active.first
    unless template
      raise StandardError, "メールテンプレートを有効化してください"
    end

    # テンプレートから件名と本文を取得
    variables = build_template_variables

    subject = template.render_subject(variables)
    # 本文はERBテンプレートを使用するため、変数をインスタンス変数として設定
    @template_body = template.render_body(variables)

    mail(
      to: @customer.email,
      subject: subject,
      headers: {
        "X-Invoice-Delivery-ID" => @delivery_id.to_s
      }
    )
  end

  private

  def company_email
    company_info = CompanyInformation.first
    # メールアドレスが設定されていない場合はデフォルトを使用
    company_info&.email.presence || "noreply@example.com"
  end

  def build_template_variables
    {
      customer_name: @customer.company_name,
      invoice_number: @invoice.invoice_number,
      invoice_date: @invoice.invoice_date.strftime("%Y年%m月%d日"),
      due_date: @invoice.due_date ? @invoice.due_date.strftime("%Y年%m月%d日") : "",
      total_amount: number_to_currency(@invoice.total_amount),
      company_name: @company_info&.name || "",
      company_phone: @company_info&.phone_number || ""
    }
  end

  def number_to_currency(amount)
    "¥#{amount.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')}"
  end
end
