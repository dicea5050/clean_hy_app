class RenamePasswordToPasswordDigestInCustomers < ActiveRecord::Migration[7.1]
  def change
    rename_column :customers, :password, :password_digest
  end
end