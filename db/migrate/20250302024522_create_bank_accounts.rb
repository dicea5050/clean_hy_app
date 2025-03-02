class CreateBankAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :bank_accounts do |t|
      t.string :bank_name, null: false
      t.string :branch_name, null: false
      t.string :account_type, null: false
      t.string :account_number, null: false
      t.string :account_holder, null: false

      t.timestamps
    end
  end
end
