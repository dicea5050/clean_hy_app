class RemovePendingStatusFromInvoices < ActiveRecord::Migration[8.0]
  def up
    # approver_typeとapprover_idをnull許可に変更（先に実行）
    change_column_null :invoice_approvals, :approver_type, true
    change_column_null :invoice_approvals, :approver_id, true
    
    # 既存の「未申請」ステータスの請求書を「承認待ち」に変更
    Invoice.where(approval_status: '未申請').find_each do |invoice|
      # 請求書のステータスを「承認待ち」に変更
      invoice.update_column(:approval_status, '承認待ち')
      
      # InvoiceApprovalレコードが存在しない場合は作成
      unless InvoiceApproval.exists?(invoice_id: invoice.id)
        InvoiceApproval.create!(
          invoice_id: invoice.id,
          status: InvoiceApproval::STATUSES[:pending]
          # approverは承認時点で設定されるため、作成時は設定しない
        )
      end
    end
    
    # デフォルト値を「承認待ち」に変更
    change_column_default :invoices, :approval_status, '承認待ち'
  end

  def down
    # デフォルト値を「未申請」に戻す
    change_column_default :invoices, :approval_status, '未申請'
    
    # 「承認待ち」でInvoiceApprovalが存在する請求書を「未申請」に戻す
    # （完全な復元は困難なため、可能な範囲で復元）
    Invoice.where(approval_status: '承認待ち').find_each do |invoice|
      # InvoiceApprovalが存在し、かつstatusが「承認待ち」の場合のみ「未申請」に戻す
      approval = InvoiceApproval.find_by(invoice_id: invoice.id, status: '承認待ち')
      if approval && approval.approver_id.nil?
        invoice.update_column(:approval_status, '未申請')
        approval.destroy
      end
    end
    
    # approver_typeとapprover_idをNOT NULLに戻す（既存のnull値をダミー値に設定）
    InvoiceApproval.where(approver_type: nil).update_all(approver_type: 'Administrator', approver_id: 0)
    change_column_null :invoice_approvals, :approver_type, false
    change_column_null :invoice_approvals, :approver_id, false
  end
end
