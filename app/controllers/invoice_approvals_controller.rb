class InvoiceApprovalsController < ApplicationController
  before_action :require_admin_only
  before_action :require_administrator_login
  before_action :set_invoice_approval, only: [ :approve, :reject ]

  private

  def require_administrator_login
    unless administrator_signed_in?
      redirect_to login_path, alert: "管理者としてログインしてください。"
    end
  end

  def set_invoice_approval
    @invoice_approval = InvoiceApproval.find(params[:id])
  end

  public

  def index
    @invoice_approvals = InvoiceApproval.includes(:invoice)
                                      .where(status: InvoiceApproval::STATUSES[:pending])
                                      .order(created_at: :desc)
                                      .page(params[:page])
                                      .per(25)
  end

  def approve
    invoice = @invoice_approval.invoice

    Rails.logger.debug "=== 承認処理開始 ==="
    Rails.logger.debug "InvoiceApproval ID: #{@invoice_approval.id}"
    Rails.logger.debug "Invoice ID: #{invoice.id}"
    Rails.logger.debug "Invoice Number: #{invoice.invoice_number}"
    Rails.logger.debug "更新前のInvoiceApproval status: #{@invoice_approval.status}"
    Rails.logger.debug "更新前のInvoice approval_status: #{invoice.approval_status}"
    Rails.logger.debug "設定するInvoiceApproval status: #{InvoiceApproval::STATUSES[:approved]}"
    Rails.logger.debug "設定するInvoice approval_status: #{Invoice::APPROVAL_STATUSES[:approved]}"

    ActiveRecord::Base.transaction do
      # InvoiceApprovalの更新
      Rails.logger.debug "InvoiceApprovalを更新中..."
      result1 = @invoice_approval.update!(
        status: InvoiceApproval::STATUSES[:approved],
        approved_at: Time.current,
        approver: current_administrator
      )
      Rails.logger.debug "InvoiceApproval更新結果: #{result1}"
      Rails.logger.debug "更新後のInvoiceApproval status: #{@invoice_approval.reload.status}"

      # Invoiceの更新
      Rails.logger.debug "Invoiceを更新中..."
      result2 = invoice.update!(
        approval_status: Invoice::APPROVAL_STATUSES[:approved]
      )
      Rails.logger.debug "Invoice更新結果: #{result2}"
      Rails.logger.debug "更新後のInvoice approval_status: #{invoice.reload.approval_status}"

      # 更新後の確認
      Rails.logger.debug "=== 更新後の確認 ==="
      Rails.logger.debug "InvoiceApproval.reload.status: #{@invoice_approval.reload.status}"
      Rails.logger.debug "Invoice.reload.approval_status: #{invoice.reload.approval_status}"

      # バリデーションエラーの確認
      if @invoice_approval.errors.any?
        Rails.logger.error "InvoiceApprovalバリデーションエラー: #{@invoice_approval.errors.full_messages.join(', ')}"
      end
      if invoice.errors.any?
        Rails.logger.error "Invoiceバリデーションエラー: #{invoice.errors.full_messages.join(', ')}"
      end
    end

    Rails.logger.debug "=== 承認処理完了 ==="
    redirect_to invoice_approvals_path, notice: "請求書 #{invoice.invoice_number} を承認しました。"
  rescue => e
    Rails.logger.error "=== 承認処理エラー ==="
    Rails.logger.error "エラーメッセージ: #{e.message}"
    Rails.logger.error "エラークラス: #{e.class}"
    Rails.logger.error "バックトレース:"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to invoice_approvals_path, alert: "承認に失敗しました: #{e.message}"
  end

  def reject
    invoice = @invoice_approval.invoice

    Rails.logger.debug "=== 差し戻し処理開始 ==="
    Rails.logger.debug "InvoiceApproval ID: #{@invoice_approval.id}"
    Rails.logger.debug "Invoice ID: #{invoice.id}"
    Rails.logger.debug "Invoice Number: #{invoice.invoice_number}"
    Rails.logger.debug "更新前のInvoiceApproval status: #{@invoice_approval.status}"
    Rails.logger.debug "更新前のInvoice approval_status: #{invoice.approval_status}"

    rejection_reason = params[:rejection_reason]

    ActiveRecord::Base.transaction do
      update_params = {
        status: InvoiceApproval::STATUSES[:rejected],
        approver: current_administrator
      }
      update_params[:notes] = rejection_reason if rejection_reason.present?

      result1 = @invoice_approval.update!(update_params)
      Rails.logger.debug "InvoiceApproval更新結果: #{result1}"
      Rails.logger.debug "更新後のInvoiceApproval status: #{@invoice_approval.reload.status}"

      result2 = invoice.update!(
        approval_status: Invoice::APPROVAL_STATUSES[:rejected]
      )
      Rails.logger.debug "Invoice更新結果: #{result2}"
      Rails.logger.debug "更新後のInvoice approval_status: #{invoice.reload.approval_status}"

      if @invoice_approval.errors.any?
        Rails.logger.error "InvoiceApprovalバリデーションエラー: #{@invoice_approval.errors.full_messages.join(', ')}"
      end
      if invoice.errors.any?
        Rails.logger.error "Invoiceバリデーションエラー: #{invoice.errors.full_messages.join(', ')}"
      end
    end

    Rails.logger.debug "=== 差し戻し処理完了 ==="
    redirect_to invoice_approvals_path, notice: "請求書 #{invoice.invoice_number} を差し戻しました。"
  rescue => e
    Rails.logger.error "=== 差し戻し処理エラー ==="
    Rails.logger.error "エラーメッセージ: #{e.message}"
    Rails.logger.error "エラークラス: #{e.class}"
    Rails.logger.error "バックトレース:"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to invoice_approvals_path, alert: "差し戻しに失敗しました: #{e.message}"
  end

  def create
  end

  def bulk_create
    invoice_ids = params[:invoice_ids]&.split(",")

    if invoice_ids.blank?
      return redirect_to invoices_path, alert: "請求書が選択されていません。"
    end

    Rails.logger.debug "=== 一括承認申請処理開始 ==="
    Rails.logger.debug "請求書ID数: #{invoice_ids.size}"
    Rails.logger.debug "請求書IDs: #{invoice_ids.join(', ')}"

    ActiveRecord::Base.transaction do
      invoice_ids.each do |invoice_id|
        Rails.logger.debug "--- 請求書ID: #{invoice_id} の処理開始 ---"
        invoice = Invoice.find(invoice_id)
        Rails.logger.debug "更新前のInvoice approval_status: #{invoice.approval_status}"

        approval = InvoiceApproval.create!(
          invoice_id: invoice_id,
          status: InvoiceApproval::STATUSES[:pending]
          # approverは承認時点で設定されるため、作成時は設定しない
        )
        Rails.logger.debug "InvoiceApproval作成結果: ID=#{approval.id}, status=#{approval.status}"

        # 請求書の状態も更新
        result = invoice.update!(approval_status: Invoice::APPROVAL_STATUSES[:waiting])
        Rails.logger.debug "Invoice更新結果: #{result}"
        Rails.logger.debug "更新後のInvoice approval_status: #{invoice.reload.approval_status}"

        if invoice.errors.any?
          Rails.logger.error "Invoiceバリデーションエラー: #{invoice.errors.full_messages.join(', ')}"
        end
        Rails.logger.debug "--- 請求書ID: #{invoice_id} の処理完了 ---"
      end
    end

    Rails.logger.debug "=== 一括承認申請処理完了 ==="
    redirect_to invoices_path, notice: "#{invoice_ids.size}件の請求書を承認申請しました。"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "=== 一括承認申請処理エラー ==="
    Rails.logger.error "エラーメッセージ: #{e.message}"
    Rails.logger.error "エラークラス: #{e.class}"
    Rails.logger.error "バックトレース:"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to invoices_path, alert: "承認申請に失敗しました: #{e.message}"
  end

  def bulk_approve
    approval_ids = params[:approval_ids]&.split(",")

    if approval_ids.blank?
      return redirect_to invoice_approvals_path, alert: "請求書が選択されていません。"
    end

    Rails.logger.debug "=== 一括承認処理開始 ==="
    Rails.logger.debug "承認ID数: #{approval_ids.size}"
    Rails.logger.debug "承認IDs: #{approval_ids.join(', ')}"

    success_count = 0
    error_count = 0

    ActiveRecord::Base.transaction do
      approval_ids.each do |approval_id|
        Rails.logger.debug "--- 承認ID: #{approval_id} の処理開始 ---"
        approval = InvoiceApproval.find(approval_id)
        invoice = approval.invoice

        # 承認待ちステータスのみ処理
        unless approval.status == InvoiceApproval::STATUSES[:pending]
          Rails.logger.warn "承認ID: #{approval_id} は承認待ちステータスではありません（現在のステータス: #{approval.status}）"
          error_count += 1
          next
        end

        # InvoiceApprovalの更新
        result1 = approval.update!(
          status: InvoiceApproval::STATUSES[:approved],
          approved_at: Time.current,
          approver: current_administrator
        )
        Rails.logger.debug "InvoiceApproval更新結果: #{result1}"

        # Invoiceの更新
        result2 = invoice.update!(
          approval_status: Invoice::APPROVAL_STATUSES[:approved]
        )
        Rails.logger.debug "Invoice更新結果: #{result2}"

        if approval.errors.any? || invoice.errors.any?
          Rails.logger.error "バリデーションエラー: approval=#{approval.errors.full_messages.join(', ')}, invoice=#{invoice.errors.full_messages.join(', ')}"
          error_count += 1
        else
          success_count += 1
        end
        Rails.logger.debug "--- 承認ID: #{approval_id} の処理完了 ---"
      end
    end

    Rails.logger.debug "=== 一括承認処理完了 ==="
    Rails.logger.debug "成功: #{success_count}, エラー: #{error_count}"

    if success_count > 0
      redirect_to invoice_approvals_path, notice: "#{success_count}件の請求書を承認しました。"
    else
      redirect_to invoice_approvals_path, alert: "承認に失敗しました。"
    end
  rescue => e
    Rails.logger.error "=== 一括承認処理エラー ==="
    Rails.logger.error "エラーメッセージ: #{e.message}"
    Rails.logger.error "エラークラス: #{e.class}"
    Rails.logger.error "バックトレース:"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to invoice_approvals_path, alert: "承認に失敗しました: #{e.message}"
  end

  def bulk_reject
    approval_ids = params[:approval_ids]&.split(",")

    if approval_ids.blank?
      return redirect_to invoice_approvals_path, alert: "請求書が選択されていません。"
    end

    Rails.logger.debug "=== 一括差し戻し処理開始 ==="
    Rails.logger.debug "承認ID数: #{approval_ids.size}"
    Rails.logger.debug "承認IDs: #{approval_ids.join(', ')}"

    rejection_reason = params[:rejection_reason]
    success_count = 0
    error_count = 0

    ActiveRecord::Base.transaction do
      approval_ids.each do |approval_id|
        Rails.logger.debug "--- 承認ID: #{approval_id} の処理開始 ---"
        approval = InvoiceApproval.find(approval_id)
        invoice = approval.invoice

        # 承認待ちステータスのみ処理
        unless approval.status == InvoiceApproval::STATUSES[:pending]
          Rails.logger.warn "承認ID: #{approval_id} は承認待ちステータスではありません（現在のステータス: #{approval.status}）"
          error_count += 1
          next
        end

        # InvoiceApprovalの更新
        update_params = {
          status: InvoiceApproval::STATUSES[:rejected],
          approver: current_administrator
        }
        update_params[:notes] = rejection_reason if rejection_reason.present?

        result1 = approval.update!(update_params)
        Rails.logger.debug "InvoiceApproval更新結果: #{result1}"

        # Invoiceの更新
        result2 = invoice.update!(
          approval_status: Invoice::APPROVAL_STATUSES[:rejected]
        )
        Rails.logger.debug "Invoice更新結果: #{result2}"

        if approval.errors.any? || invoice.errors.any?
          Rails.logger.error "バリデーションエラー: approval=#{approval.errors.full_messages.join(', ')}, invoice=#{invoice.errors.full_messages.join(', ')}"
          error_count += 1
        else
          success_count += 1
        end
        Rails.logger.debug "--- 承認ID: #{approval_id} の処理完了 ---"
      end
    end

    Rails.logger.debug "=== 一括差し戻し処理完了 ==="
    Rails.logger.debug "成功: #{success_count}, エラー: #{error_count}"

    if success_count > 0
      redirect_to invoice_approvals_path, notice: "#{success_count}件の請求書を差し戻しました。"
    else
      redirect_to invoice_approvals_path, alert: "差し戻しに失敗しました。"
    end
  rescue => e
    Rails.logger.error "=== 一括差し戻し処理エラー ==="
    Rails.logger.error "エラーメッセージ: #{e.message}"
    Rails.logger.error "エラークラス: #{e.class}"
    Rails.logger.error "バックトレース:"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to invoice_approvals_path, alert: "差し戻しに失敗しました: #{e.message}"
  end
end
