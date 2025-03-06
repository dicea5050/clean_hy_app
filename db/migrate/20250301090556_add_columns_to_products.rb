class AddColumnsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :is_public, :boolean, default: true
    add_column :products, :stock, :integer, default: nil, null: true
  end
end
