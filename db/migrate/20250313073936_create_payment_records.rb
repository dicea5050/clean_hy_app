class CreatePaymentRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_records do |t|
      t.references :invoice, null: false, foreign_key: true
      t.date :payment_date
      t.string :payment_type
      t.decimal :amount, precision: 12, scale: 2
      t.text :memo

      t.timestamps
    end
  end
end
