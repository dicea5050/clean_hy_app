class CreateEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :email_templates do |t|
      t.string :name, null: false
      t.text :subject, null: false
      t.text :body, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :email_templates, :name, unique: true
    add_index :email_templates, :is_active
  end
end
