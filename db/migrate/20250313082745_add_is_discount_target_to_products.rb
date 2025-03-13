class AddIsDiscountTargetToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :is_discount_target, :boolean, default: false, null: false
  end
end
