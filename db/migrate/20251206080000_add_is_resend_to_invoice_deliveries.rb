class AddIsResendToInvoiceDeliveries < ActiveRecord::Migration[8.0]
  def change
    add_column :invoice_deliveries, :is_resend, :boolean, default: false, null: false
  end
end
