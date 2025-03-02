class AddInvoiceDeliveryMethodToCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :customers, :invoice_delivery_method, :integer, default: 0
  end
end
