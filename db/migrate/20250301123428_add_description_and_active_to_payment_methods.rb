class AddDescriptionAndActiveToPaymentMethods < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_methods, :description, :text
    add_column :payment_methods, :active, :boolean, default: true
  end
end
