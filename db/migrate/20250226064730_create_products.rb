class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :product_code
      t.string :name
      t.references :tax_rate, null: false, foreign_key: true

      t.timestamps
    end
  end
end
