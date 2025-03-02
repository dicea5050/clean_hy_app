class FixPaymentMethodIdMigration < ActiveRecord::Migration[6.0]
  def change
    # 既にカラムが作成されていれば何もしない、なければ作成
    unless column_exists?(:orders, :payment_method_id)
      add_column :orders, :payment_method_id, :integer
      add_index :orders, :payment_method_id
    end
    
    # 既存データの移行処理は削除（必要に応じて後で手動で行う）
  end
end