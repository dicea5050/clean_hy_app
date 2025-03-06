class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :invoice_number, null: false
      t.references :customer, null: false, foreign_key: true
      t.date :invoice_date, null: false
      t.date :due_date
      t.text :notes

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
  end
end
