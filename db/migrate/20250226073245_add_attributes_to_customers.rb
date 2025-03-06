class AddAttributesToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :customer_code, :string
    add_column :customers, :company_name, :string
    add_column :customers, :postal_code, :string
    add_column :customers, :address, :string
    add_column :customers, :contact_name, :string
    add_column :customers, :phone_number, :string
    add_column :customers, :email, :string

    add_index :customers, :customer_code, unique: true
  end
end
