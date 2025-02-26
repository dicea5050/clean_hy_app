class CreateInvoiceOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_orders do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :invoice_orders, [:invoice_id, :order_id], unique: true
  end
end