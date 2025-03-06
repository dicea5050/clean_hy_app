class AddIsDiscountToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :is_discount, :boolean
  end
end
