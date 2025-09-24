class AddIssueTrackingToInvoices < ActiveRecord::Migration[7.0]
  def change
    add_column :invoices, :first_issued_at, :datetime
    add_column :invoices, :last_issued_at, :datetime
    add_column :invoices, :issued_count, :integer, null: false, default: 0
  end
end
