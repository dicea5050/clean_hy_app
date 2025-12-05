class CreateProductAggregationGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :product_aggregation_groups do |t|
      t.integer :fiscal_year, null: false
      t.references :product_category, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :group_code
      t.string :group_name, null: false

      t.timestamps
    end

    add_index :product_aggregation_groups, [:fiscal_year, :product_category_id, :product_id], unique: true, name: 'index_pag_on_fiscal_year_and_category_and_product'
    add_index :product_aggregation_groups, [:fiscal_year, :product_category_id, :group_code], name: 'index_pag_on_fiscal_year_and_category_and_group_code'
  end
end
