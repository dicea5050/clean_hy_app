class CreateInvoiceDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_deliveries do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :delivery_method
      t.string :delivery_status
      t.datetime :sent_at
      t.integer :sent_by
      t.text :notes

      t.timestamps
    end
  end
end
