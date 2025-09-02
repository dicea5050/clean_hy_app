class AddProductNameOverrideToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :order_items, :product_name_override, :string
  end
end
