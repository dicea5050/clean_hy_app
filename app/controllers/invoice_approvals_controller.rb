class InvoiceApprovalsController < ApplicationController
  before_action :require_administrator_login
  before_action :set_invoice_approval, only: [:approve, :reject]

  private

  def require_administrator_login
    unless administrator_signed_in?
      redirect_to login_path, alert: '管理者としてログインしてください。'
    end
  end

  def set_invoice_approval
    @invoice_approval = InvoiceApproval.find(params[:id])
  end

  public

  def index
    @invoice_approvals = InvoiceApproval.includes(:invoice, invoice: :customer)
                                      .where(status: InvoiceApproval::STATUSES[:pending])
                                      .order(created_at: :desc)
  end

  def approve
    ActiveRecord::Base.transaction do
      @invoice_approval.update!(
        status: InvoiceApproval::STATUSES[:approved],
        approved_at: Time.current
      )
      @invoice_approval.invoice.update!(
        approval_status: Invoice::APPROVAL_STATUSES[:approved]
      )
    end

    redirect_to invoice_approvals_path, notice: "請求書 #{@invoice_approval.invoice.invoice_number} を承認しました。"
  rescue => e
    redirect_to invoice_approvals_path, alert: "承認に失敗しました: #{e.message}"
  end

  def reject
    ActiveRecord::Base.transaction do
      @invoice_approval.update!(
        status: InvoiceApproval::STATUSES[:rejected]
      )
      @invoice_approval.invoice.update!(
        approval_status: Invoice::APPROVAL_STATUSES[:rejected]
      )
    end

    redirect_to invoice_approvals_path, notice: "請求書 #{@invoice_approval.invoice.invoice_number} を差し戻しました。"
  rescue => e
    redirect_to invoice_approvals_path, alert: "差し戻しに失敗しました: #{e.message}"
  end

  def create
  end

  def bulk_create
    invoice_ids = params[:invoice_ids]&.split(',')
    
    if invoice_ids.blank?
      return redirect_to invoices_path, alert: '請求書が選択されていません。'
    end

    ActiveRecord::Base.transaction do
      invoice_ids.each do |invoice_id|
        InvoiceApproval.create!(
          invoice_id: invoice_id,
          status: InvoiceApproval::STATUSES[:pending],
          approver: current_administrator # 管理者による承認
        )

        # 請求書の状態も更新
        invoice = Invoice.find(invoice_id)
        invoice.update!(approval_status: Invoice::APPROVAL_STATUSES[:waiting])
      end
    end

    redirect_to invoices_path, notice: "#{invoice_ids.size}件の請求書を承認申請しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to invoices_path, alert: "承認申請に失敗しました: #{e.message}"
  end
end
