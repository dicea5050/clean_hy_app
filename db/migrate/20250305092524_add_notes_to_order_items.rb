class AddNotesToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :order_items, :notes, :text
  end
end
