class AddIsMainOfficeToDeliveryLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :delivery_locations, :is_main_office, :boolean, default: false
    add_index :delivery_locations, [:customer_id, :is_main_office], unique: true, where: "is_main_office = true", name: 'index_delivery_locations_on_customer_id_and_main_office'
  end
end
