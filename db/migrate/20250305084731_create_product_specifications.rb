class CreateProductSpecifications < ActiveRecord::Migration[7.0]
  def change
    create_table :product_specifications do |t|
      t.string :name, null: false
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end
    add_index :product_specifications, :name, unique: true
  end
end
