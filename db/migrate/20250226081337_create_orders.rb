class CreateOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.date :order_date, null: false
      t.date :expected_delivery_date
      t.date :actual_delivery_date

      t.timestamps
    end
  end
end 