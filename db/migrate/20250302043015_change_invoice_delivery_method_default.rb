class ChangeInvoiceDeliveryMethodDefault < ActiveRecord::Migration[6.1]
  def change
    change_column_default :customers, :invoice_delivery_method, from: 0, to: nil
  end
end
