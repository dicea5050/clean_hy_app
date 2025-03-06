class CreateInvoiceApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_approvals do |t|
      t.references :invoice, null: false, foreign_key: true, index: true
      t.string :status, null: false
      t.references :approver, polymorphic: true, null: false, index: true
      t.datetime :approved_at
      t.text :notes

      t.timestamps
    end

    add_index :invoice_approvals, [ :invoice_id, :status ]
  end
end
