class AddFaxNumberToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :fax_number, :string
  end
end
