class RefactorPaymentRecords < ActiveRecord::Migration[8.0]
  def up
    # 既存データを削除
    execute "DELETE FROM payment_records"
    
    # 外部キー制約を削除
    remove_foreign_key :payment_records, :invoices
    
    # invoice_idをnull許可に変更
    change_column_null :payment_records, :invoice_id, true
    
    # customer_idカラムを追加
    add_reference :payment_records, :customer, null: false, foreign_key: true
    
    # payment_typeをcategoryにリネーム
    rename_column :payment_records, :payment_type, :category
    
    # memoをnotesにリネーム
    rename_column :payment_records, :memo, :notes
    
    # amountの型をdecimalからintegerに変更
    change_column :payment_records, :amount, :integer, null: false
    
    # paid_amountカラムを追加
    add_column :payment_records, :paid_amount, :integer, null: false, default: 0
  end

  def down
    # paid_amountカラムを削除
    remove_column :payment_records, :paid_amount
    
    # amountの型をintegerからdecimalに戻す
    change_column :payment_records, :amount, :decimal, precision: 12, scale: 2
    
    # notesをmemoにリネーム
    rename_column :payment_records, :notes, :memo
    
    # categoryをpayment_typeにリネーム
    rename_column :payment_records, :category, :payment_type
    
    # customer_idを削除
    remove_reference :payment_records, :customer, foreign_key: true
    
    # invoice_idをnull不許可に戻す
    change_column_null :payment_records, :invoice_id, false
    
    # 外部キー制約を復元
    add_foreign_key :payment_records, :invoices
  end
end
