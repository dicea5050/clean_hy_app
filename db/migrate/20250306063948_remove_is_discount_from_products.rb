class RemoveIsDiscountFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :is_discount, :boolean
  end
end
