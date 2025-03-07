class AddDepartmentToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :department, :string
  end
end
