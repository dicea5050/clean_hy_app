class CreateTaxRates < ActiveRecord::Migration[6.1]
  def change
    create_table :tax_rates do |t|
      t.string :name, null: false
      t.decimal :rate, null: false, precision: 5, scale: 2
      t.date :start_date, null: false
      t.date :end_date

      t.timestamps
    end
  end
end