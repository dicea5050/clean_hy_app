class CreateDeliveryLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_locations do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :name
      t.string :postal_code
      t.string :address
      t.string :phone
      t.string :contact_person

      t.timestamps
    end
  end
end
