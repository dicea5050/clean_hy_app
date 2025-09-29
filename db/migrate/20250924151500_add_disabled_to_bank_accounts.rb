class AddDisabledToBankAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :bank_accounts, :disabled, :boolean, null: false, default: false
  end
end
