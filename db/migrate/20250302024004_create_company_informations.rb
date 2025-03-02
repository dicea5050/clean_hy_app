class CreateCompanyInformations < ActiveRecord::Migration[7.0]
  def change
    create_table :company_informations do |t|
      t.string :name, null: false
      t.string :postal_code, null: false
      t.text :address, null: false
      t.string :phone_number, null: false
      t.string :fax_number
      t.string :invoice_registration_number, null: false

      t.timestamps
    end
    add_index :company_informations, :name
  end
end
