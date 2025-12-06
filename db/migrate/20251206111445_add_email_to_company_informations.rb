class AddEmailToCompanyInformations < ActiveRecord::Migration[8.0]
  def change
    add_column :company_informations, :email, :string
  end
end
