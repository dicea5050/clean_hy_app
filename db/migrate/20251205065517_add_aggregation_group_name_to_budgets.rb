class AddAggregationGroupNameToBudgets < ActiveRecord::Migration[8.0]
  def change
    add_column :budgets, :aggregation_group_name, :string
  end
end
