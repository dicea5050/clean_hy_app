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

ActiveRecord::Schema[8.0].define(version: 2025_03_01_090556) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "administrators", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_administrators_on_email", unique: true
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
    t.index ["customer_code"], name: "index_customers_on_customer_code", unique: true
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
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.date "order_date", null: false
    t.date "expected_delivery_date"
    t.date "actual_delivery_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_method"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
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

  add_foreign_key "invoice_orders", "invoices"
  add_foreign_key "invoice_orders", "orders"
  add_foreign_key "invoices", "customers"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "customers"
  add_foreign_key "products", "tax_rates"
end
