class CreateAdministrators < ActiveRecord::Migration[7.0]
  def change
    create_table :administrators do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.integer :role, default: 0, null: false

      t.timestamps
    end
    add_index :administrators, :email, unique: true
  end
end
