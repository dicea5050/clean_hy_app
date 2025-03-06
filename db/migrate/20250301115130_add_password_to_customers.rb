class AddPasswordToCustomers < ActiveRecord::Migration[7.0]
  def change
    # 古いpasswordカラムを削除
    remove_column :customers, :password, :string if column_exists?(:customers, :password)

    # password_digestカラムを追加（has_secure_password用）
    add_column :customers, :password_digest, :string unless column_exists?(:customers, :password_digest)
  end
end
