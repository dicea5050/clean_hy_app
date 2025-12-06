class AddIsShopOrderToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :is_shop_order, :boolean, default: false, null: false
  end
end
