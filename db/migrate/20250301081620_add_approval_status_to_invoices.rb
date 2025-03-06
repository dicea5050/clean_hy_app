class AddApprovalStatusToInvoices < ActiveRecord::Migration[7.0]
  def change
    add_column :invoices, :approval_status, :string, default: '未申請', null: false
  end
end
