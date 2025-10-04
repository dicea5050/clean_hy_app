class ChangeQuantityToDecimalInOrderItems < ActiveRecord::Migration[8.0]
  def change
    change_column :order_items, :quantity, :decimal, precision: 10, scale: 2, null: false, default: 1
  end
end
