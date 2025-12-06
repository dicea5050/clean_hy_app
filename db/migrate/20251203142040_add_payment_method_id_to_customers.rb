class AddPaymentMethodIdToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_reference :customers, :payment_method, null: true, foreign_key: true
  end
end
