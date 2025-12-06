class CreateBudgets < ActiveRecord::Migration[8.0]
  def change
    create_table :budgets do |t|
      t.integer :fiscal_year, null: false
      t.bigint :product_category_id, null: false
      t.bigint :product_id
      t.integer :budget_amount, null: false, default: 0

      t.timestamps
    end

    add_index :budgets, [ :fiscal_year, :product_category_id, :product_id ], unique: true, name: 'index_budgets_on_fiscal_year_and_category_and_product'
    add_index :budgets, :product_category_id
    add_index :budgets, :product_id
    add_foreign_key :budgets, :product_categories
    add_foreign_key :budgets, :products
  end
end
