class ChangeQuantityPrecisionToThree < ActiveRecord::Migration[8.0]
  def up
    # order_itemsテーブルのquantityカラムの精度を小数3桁に変更
    change_column :order_items, :quantity, :decimal, precision: 10, scale: 3, default: 1.0, null: false
  end

  def down
    # 元に戻す場合は元の精度に戻す
    change_column :order_items, :quantity, :decimal, precision: 10, scale: 2, default: 1.0, null: false
  end
end
