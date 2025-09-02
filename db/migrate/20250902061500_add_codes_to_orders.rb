class AddCodesToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :customer_code, :string
    add_column :orders, :product_code, :string
    
    add_index :orders, :customer_code
    add_index :orders, :product_code
  end
end
