class AddProductSpecificationToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :order_items, :product_specification, foreign_key: true
  end
end
