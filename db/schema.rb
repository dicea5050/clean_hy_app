# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_03_13_082745) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "administrators", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_administrators_on_email", unique: true
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.string "bank_name", null: false
    t.string "branch_name", null: false
    t.string "account_type", null: false
    t.string "account_number", null: false
    t.string "account_holder", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "company_informations", force: :cascade do |t|
    t.string "name", null: false
    t.string "postal_code", null: false
    t.text "address", null: false
    t.string "phone_number", null: false
    t.string "fax_number"
    t.string "invoice_registration_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "representative_name"
    t.index ["name"], name: "index_company_informations_on_name"
  end

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "customer_code"
    t.string "company_name"
    t.string "postal_code"
    t.string "address"
    t.string "contact_name"
    t.string "phone_number"
    t.string "email"
    t.string "password_digest"
    t.integer "invoice_delivery_method"
    t.string "department"
    t.index ["customer_code"], name: "index_customers_on_customer_code", unique: true
  end

  create_table "delivery_locations", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "name"
    t.string "postal_code"
    t.string "address"
    t.string "phone"
    t.string "contact_person"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_main_office", default: false
    t.index ["customer_id", "is_main_office"], name: "index_delivery_locations_on_customer_id_and_main_office", unique: true, where: "(is_main_office = true)"
    t.index ["customer_id"], name: "index_delivery_locations_on_customer_id"
  end

  create_table "invoice_approvals", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "status", null: false
    t.string "approver_type", null: false
    t.bigint "approver_id", null: false
    t.datetime "approved_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_type", "approver_id"], name: "index_invoice_approvals_on_approver"
    t.index ["invoice_id", "status"], name: "index_invoice_approvals_on_invoice_id_and_status"
    t.index ["invoice_id"], name: "index_invoice_approvals_on_invoice_id"
  end

  create_table "invoice_orders", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.bigint "order_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "order_id"], name: "index_invoice_orders_on_invoice_id_and_order_id", unique: true
    t.index ["invoice_id"], name: "index_invoice_orders_on_invoice_id"
    t.index ["order_id"], name: "index_invoice_orders_on_order_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "invoice_number", null: false
    t.bigint "customer_id", null: false
    t.date "invoice_date", null: false
    t.date "due_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "approval_status", default: "未申請", null: false
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "tax_rate", precision: 5, scale: 2, default: "10.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.bigint "unit_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["unit_id"], name: "index_order_items_on_unit_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.date "order_date", null: false
    t.date "expected_delivery_date"
    t.date "actual_delivery_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_method"
    t.integer "payment_method_id"
    t.bigint "delivery_location_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["delivery_location_id"], name: "index_orders_on_delivery_location_id"
    t.index ["payment_method_id"], name: "index_orders_on_payment_method_id"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.boolean "active", default: true
  end

  create_table "payment_records", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.date "payment_date"
    t.string "payment_type"
    t.decimal "amount", precision: 12, scale: 2
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payment_records_on_invoice_id"
  end

  create_table "product_specifications", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_product_specifications_on_name", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "product_code"
    t.string "name"
    t.bigint "tax_rate_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price"
    t.boolean "is_public", default: true
    t.integer "stock"
    t.boolean "is_discount_target", default: false, null: false
    t.index ["tax_rate_id"], name: "index_products_on_tax_rate_id"
  end

  create_table "tax_rates", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "rate", precision: 5, scale: 2, null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "units", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "delivery_locations", "customers"
  add_foreign_key "invoice_approvals", "invoices"
  add_foreign_key "invoice_orders", "invoices"
  add_foreign_key "invoice_orders", "orders"
  add_foreign_key "invoices", "customers"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_items", "units"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "delivery_locations"
  add_foreign_key "payment_records", "invoices"
  add_foreign_key "products", "tax_rates"
end
