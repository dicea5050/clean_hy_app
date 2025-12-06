class UpdateBudgetsUniqueIndex < ActiveRecord::Migration[8.0]
  def up
    # 既存のユニークインデックスを削除
    remove_index :budgets, name: 'index_budgets_on_fiscal_year_and_category_and_product'

    # 新しいユニークインデックスを追加（aggregation_group_nameを含む）
    add_index :budgets, [ :fiscal_year, :product_category_id, :product_id, :aggregation_group_name ],
              unique: true,
              name: 'index_budgets_on_fiscal_year_and_category_and_product_and_group'
  end

  def down
    # 新しいインデックスを削除
    remove_index :budgets, name: 'index_budgets_on_fiscal_year_and_category_and_product_and_group'

    # 元のインデックスを復元
    add_index :budgets, [ :fiscal_year, :product_category_id, :product_id ],
              unique: true,
              name: 'index_budgets_on_fiscal_year_and_category_and_product'
  end
end
