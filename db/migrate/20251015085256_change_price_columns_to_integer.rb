class ChangePriceColumnsToInteger < ActiveRecord::Migration[8.0]
  def up
    # productsテーブルのpriceカラムを整数に変更
    change_column :products, :price, :integer
    
    # order_itemsテーブルのunit_priceカラムを整数に変更
    change_column :order_items, :unit_price, :integer
  end

  def down
    # 元に戻す場合はdecimalに戻す
    change_column :products, :price, :decimal
    change_column :order_items, :unit_price, :decimal, precision: 10, scale: 2
  end
end
