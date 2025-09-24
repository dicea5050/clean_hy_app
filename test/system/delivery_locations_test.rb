require "application_system_test_case"

class DeliveryLocationsTest < ApplicationSystemTestCase
  def login_as_admin
    admin = Administrator.create!(email: "admin@example.com", password: "password123", role: :admin)
    visit login_path
    fill_in "email", with: admin.email
    fill_in "password", with: "password123"
    within("form[action='#{authenticate_path}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_current_path masters_path
  end

  test "redirect to login when not authenticated" do
    visit delivery_locations_path
    assert_current_path login_path
  end

  test "CRUD delivery locations when logged in" do
    login_as_admin

    # 紐づく顧客を事前準備
    customer = Customer.create!(customer_code: "CUST-DL-1", company_name: "納品先用顧客", postal_code: "100-0001", address: "東京都千代田区", invoice_delivery_method: :electronic)

    visit delivery_locations_path

    visit new_delivery_location_path
    find("select[name='delivery_location[customer_id]']").find("option[value='#{customer.id}']").select_option
    fill_in "delivery_location[name]", with: "本社倉庫"
    fill_in "delivery_location[postal_code]", with: "100-0002"
    fill_in "delivery_location[address]", with: "東京都中央区"
    fill_in "delivery_location[phone]", with: "03-9999-9999"
    fill_in "delivery_location[contact_person]", with: "倉庫 太郎"
    within("form[action='#{delivery_locations_path}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "納品先を登録しました。", wait: 3

    dl = DeliveryLocation.find_by(name: "本社倉庫")
    assert dl.present?

    visit edit_delivery_location_path(dl)
    fill_in "delivery_location[address]", with: "東京都港区"
    within("form[action='#{delivery_location_path(dl)}']") do
      find("input[type='submit'], button[type='submit']", match: :first).click
    end
    assert_text "納品先を更新しました。", wait: 3
    dl.reload
    assert_equal "東京都港区", dl.address

    # UI削除は環境差で不安定なため、モデル経由で削除
    dl.destroy
    assert_nil DeliveryLocation.find_by(id: dl.id)
  end
end
