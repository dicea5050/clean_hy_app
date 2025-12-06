class AddSesFieldsToInvoiceDeliveries < ActiveRecord::Migration[8.0]
  def change
    add_column :invoice_deliveries, :ses_message_id, :string
    add_column :invoice_deliveries, :ses_event_type, :string
    add_column :invoice_deliveries, :ses_event_timestamp, :datetime
    add_column :invoice_deliveries, :ses_error_message, :text
  end
end
