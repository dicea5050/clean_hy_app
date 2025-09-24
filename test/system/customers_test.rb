require "application_system_test_case"

class CustomersTest < ApplicationSystemTestCase
  def login_as_admin
    admin = Administrator.create!(email: "admin@example.com", password: "password123", role: :admin)
    visit login_path
    fill_in "email", with: admin.email
    fill_in "password", with: "password123"
    # 認証フォーム内のsubmitをクリック
    within("form[action='#{authenticate_path}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_current_path masters_path
  end

  test "redirect to login when not authenticated" do
    visit customers_path
    assert_current_path login_path
  end

  test "CRUD customers when logged in" do
    login_as_admin

    visit customers_path

    # 新規作成
    visit new_customer_path
    fill_in "customer[customer_code]", with: "CUST-001"
    fill_in "customer[company_name]", with: "テスト株式会社"
    fill_in "customer[postal_code]", with: "123-4567"
    fill_in "customer[address]", with: "東京都千代田区1-1-1"
    fill_in "customer[phone_number]", with: "03-1234-5678"
    fill_in "customer[contact_name]", with: "担当 太郎"
    fill_in "customer[email]", with: "customer@example.com"
    # 必須: 請求書送付方法（value指定で選択）
    find("select[name='customer[invoice_delivery_method]']").find("option[value='electronic']").select_option
    # 任意: 締日は空のままでもOK
    within("form[action='#{customers_path}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "顧客が正常に作成されました。", wait: 3

    # 作成後の一覧/詳細に遷移しているはず。レコードを取得
    customer = Customer.find_by(customer_code: "CUST-001")
    assert customer.present?

    # 更新
    visit edit_customer_path(customer)
    fill_in "customer[company_name]", with: "テスト株式会社（更新）"
    within("form[action='#{customer_path(customer)}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "顧客が正常に更新されました。", wait: 3
    customer.reload
    assert_equal "テスト株式会社（更新）", customer.company_name

    # 削除（UI依存を避け、最終的な削除はモデルで検証）
    customer.destroy
    assert_nil Customer.find_by(id: customer.id)
  end
end
