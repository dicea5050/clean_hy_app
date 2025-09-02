class CreateProductCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :product_categories do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
  end
end
