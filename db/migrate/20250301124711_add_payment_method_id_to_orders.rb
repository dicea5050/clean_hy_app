class AddPaymentMethodIdToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :payment_method_id, :integer
    add_index :orders, :payment_method_id
    
    # データ移行のSQLを削除または修正
    # 現在はデータ移行をスキップし、単にカラムを追加するだけにします
  end
end